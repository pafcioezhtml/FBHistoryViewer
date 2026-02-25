import Foundation
import GRDB

struct FeedRepository {
    let dbQueue: DatabaseQueue
    let pageSize = 50

    /// Fetches a page of feed items sorted by timestamp DESC.
    /// Pass `beforeTimestamp: nil` for the first page.
    func fetchPage(
        beforeTimestamp: Int64?,
        filter: FeedFilter,
        searchText: String = ""
    ) async throws -> [FeedItem] {
        switch filter {
        case .all:      return try await fetchMixed(beforeTimestamp: beforeTimestamp, searchText: searchText)
        case .posts:    return try await fetchPosts(beforeTimestamp: beforeTimestamp, searchText: searchText)
        case .likes:    return try await fetchLikes(beforeTimestamp: beforeTimestamp, searchText: searchText)
        case .comments: return try await fetchComments(beforeTimestamp: beforeTimestamp, searchText: searchText)
        }
    }

    // MARK: - Filtered single-table fetches

    private func fetchPosts(beforeTimestamp: Int64?, searchText: String) async throws -> [FeedItem] {
        try await dbQueue.read { db in
            var conditions: [String] = []
            var args: [DatabaseValue] = []

            if let ts = beforeTimestamp {
                conditions.append("timestamp < ?")
                args.append(ts.databaseValue)
            }
            if !searchText.isEmpty {
                conditions.append("(COALESCE(content,'') LIKE ? OR COALESCE(title,'') LIKE ? OR COALESCE(group_name,'') LIKE ?)")
                let p = "%\(searchText)%".databaseValue
                args += [p, p, p]
            }

            let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
            let sql = "SELECT * FROM posts \(where_) ORDER BY timestamp DESC LIMIT \(pageSize)"
            let records = try PostRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return records.map { .post($0) }
        }
    }

    private func fetchLikes(beforeTimestamp: Int64?, searchText: String) async throws -> [FeedItem] {
        try await dbQueue.read { db in
            var conditions: [String] = []
            var args: [DatabaseValue] = []

            if let ts = beforeTimestamp {
                conditions.append("timestamp < ?")
                args.append(ts.databaseValue)
            }
            if !searchText.isEmpty {
                conditions.append("title LIKE ?")
                args.append("%\(searchText)%".databaseValue)
            }

            let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
            let sql = "SELECT * FROM likes \(where_) ORDER BY timestamp DESC LIMIT \(pageSize)"
            let records = try LikeRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return records.map { .like($0) }
        }
    }

    private func fetchComments(beforeTimestamp: Int64?, searchText: String) async throws -> [FeedItem] {
        try await dbQueue.read { db in
            var conditions: [String] = []
            var args: [DatabaseValue] = []

            if let ts = beforeTimestamp {
                conditions.append("timestamp < ?")
                args.append(ts.databaseValue)
            }
            if !searchText.isEmpty {
                conditions.append("(COALESCE(comment_text,'') LIKE ? OR COALESCE(title,'') LIKE ?)")
                let p = "%\(searchText)%".databaseValue
                args += [p, p]
            }

            let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
            let sql = "SELECT * FROM comments \(where_) ORDER BY timestamp DESC LIMIT \(pageSize)"
            let records = try CommentRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            return records.map { .comment($0) }
        }
    }

    // MARK: - Mixed cursor-based pagination

    private func fetchMixed(beforeTimestamp: Int64?, searchText: String) async throws -> [FeedItem] {
        try await dbQueue.read { db in
            let tsFilter = beforeTimestamp.map { "WHERE timestamp < \($0)" } ?? ""

            let postSQL = """
                SELECT 'post' AS type, id, timestamp FROM posts \(tsFilter)
                ORDER BY timestamp DESC LIMIT \(pageSize)
                """
            let likeSQL = """
                SELECT 'like' AS type, id, timestamp FROM likes \(tsFilter)
                ORDER BY timestamp DESC LIMIT \(pageSize)
                """
            let commentSQL = """
                SELECT 'comment' AS type, id, timestamp FROM comments \(tsFilter)
                ORDER BY timestamp DESC LIMIT \(pageSize)
                """

            // Collect top N from each table then merge-sort
            struct Stub { let type: String; let id: Int64; let timestamp: Int64 }
            var stubs: [Stub] = []
            for row in try Row.fetchAll(db, sql: postSQL) {
                stubs.append(Stub(type: "post", id: row["id"], timestamp: row["timestamp"]))
            }
            for row in try Row.fetchAll(db, sql: likeSQL) {
                stubs.append(Stub(type: "like", id: row["id"], timestamp: row["timestamp"]))
            }
            for row in try Row.fetchAll(db, sql: commentSQL) {
                stubs.append(Stub(type: "comment", id: row["id"], timestamp: row["timestamp"]))
            }
            stubs.sort { $0.timestamp > $1.timestamp }
            let topStubs = Array(stubs.prefix(pageSize))

            // Fetch full records for the top stubs
            var postIds: [Int64] = []
            var likeIds: [Int64] = []
            var commentIds: [Int64] = []
            for s in topStubs {
                switch s.type {
                case "post":    postIds.append(s.id)
                case "like":    likeIds.append(s.id)
                case "comment": commentIds.append(s.id)
                default: break
                }
            }

            var postMap: [Int64: PostRecord] = [:]
            var likeMap: [Int64: LikeRecord] = [:]
            var commentMap: [Int64: CommentRecord] = [:]

            if !postIds.isEmpty {
                let records = try PostRecord.fetchAll(
                    db,
                    sql: "SELECT * FROM posts WHERE id IN (\(postIds.map { "\($0)" }.joined(separator: ",")))"
                )
                for r in records { postMap[r.id!] = r }
            }
            if !likeIds.isEmpty {
                let records = try LikeRecord.fetchAll(
                    db,
                    sql: "SELECT * FROM likes WHERE id IN (\(likeIds.map { "\($0)" }.joined(separator: ",")))"
                )
                for r in records { likeMap[r.id!] = r }
            }
            if !commentIds.isEmpty {
                let records = try CommentRecord.fetchAll(
                    db,
                    sql: "SELECT * FROM comments WHERE id IN (\(commentIds.map { "\($0)" }.joined(separator: ",")))"
                )
                for r in records { commentMap[r.id!] = r }
            }

            return topStubs.compactMap { s in
                switch s.type {
                case "post":    return postMap[s.id].map { .post($0) }
                case "like":    return likeMap[s.id].map { .like($0) }
                case "comment": return commentMap[s.id].map { .comment($0) }
                default: return nil
                }
            }
        }
    }
}
