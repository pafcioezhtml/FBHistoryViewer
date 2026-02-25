import Foundation
import GRDB

struct StatisticsRepository {
    let dbQueue: DatabaseQueue

    func fetchOverviewStats() async throws -> OverviewStats {
        try await dbQueue.read { db in
            let threads  = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM threads") ?? 0
            let messages = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM messages") ?? 0
            let posts    = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM posts") ?? 0
            let likes    = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM likes") ?? 0
            let comments = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM comments") ?? 0
            let reactions = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM reactions") ?? 0
            return OverviewStats(
                threadCount: threads,
                messageCount: messages,
                postCount: posts,
                likeCount: likes,
                commentCount: comments,
                reactionCount: reactions
            )
        }
    }

    func fetchMessagesPerMonth(userName: String) async throws -> [MonthCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y-%m', timestamp_ms / 1000, 'unixepoch') AS month,
                    COUNT(*) AS cnt
                FROM messages
                WHERE sender_name = ?
                GROUP BY month
                ORDER BY month ASC
                """, arguments: [userName])
            return rows.map { MonthCount(month: $0["month"], count: $0["cnt"]) }
        }
    }

    func fetchUserName() async throws -> String {
        try await dbQueue.read { db in
            (try String.fetchOne(db, sql: "SELECT name FROM profile WHERE id = 1")) ?? ""
        }
    }

    func fetchTopThreads(isGroup: Bool, limit: Int, userName: String) async throws -> [ThreadStat] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    t.id, t.title, t.message_count, t.is_group_chat,
                    t.participant_names, t.first_message_at,
                    (
                        SELECT COUNT(*)
                        FROM messages m
                        WHERE m.thread_id = t.id AND m.sender_name = ?
                    ) AS my_message_count,
                    (
                        SELECT strftime('%Y', m2.timestamp_ms / 1000, 'unixepoch')
                        FROM messages m2
                        WHERE m2.thread_id = t.id
                        GROUP BY strftime('%Y', m2.timestamp_ms / 1000, 'unixepoch')
                        ORDER BY COUNT(*) DESC
                        LIMIT 1
                    ) AS most_active_year
                FROM threads t
                WHERE t.is_group_chat = ?
                ORDER BY my_message_count DESC
                LIMIT ?
                """, arguments: [userName, isGroup ? 1 : 0, limit])
            return rows.map { row in
                let json: String = row["participant_names"] ?? "[]"
                let names = (try? JSONDecoder().decode(
                    [String].self,
                    from: Data(json.utf8)
                )) ?? []
                return ThreadStat(
                    threadId: row["id"],
                    title: row["title"],
                    messageCount: row["message_count"],
                    myMessageCount: row["my_message_count"] ?? 0,
                    isGroupChat: (row["is_group_chat"] as Int) != 0,
                    participantNames: names,
                    firstMessageAt: row["first_message_at"],
                    mostActiveYear: row["most_active_year"]
                )
            }
        }
    }

    func fetchMessagesPerMonth(threadId: Int64, userName: String) async throws -> [MonthCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y-%m', timestamp_ms / 1000, 'unixepoch') AS month,
                    COUNT(*) AS cnt
                FROM messages
                WHERE thread_id = ? AND sender_name = ?
                GROUP BY month
                ORDER BY month ASC
                """, arguments: [threadId, userName])
            return rows.map { MonthCount(month: $0["month"], count: $0["cnt"]) }
        }
    }

    func fetchActivityByHour() async throws -> [HourCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    (timestamp_ms / 3600000) % 24 AS hour,
                    COUNT(*) AS cnt
                FROM messages
                GROUP BY hour
                ORDER BY hour ASC
                """)
            return rows.map { HourCount(hour: $0["hour"], count: $0["cnt"]) }
        }
    }

    func fetchActivityByWeekday() async throws -> [WeekdayCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    CAST(strftime('%w', timestamp_ms / 1000, 'unixepoch') AS INTEGER) AS weekday,
                    COUNT(*) AS cnt
                FROM messages
                GROUP BY weekday
                ORDER BY weekday ASC
                """)
            return rows.map { WeekdayCount(weekday: $0["weekday"], count: $0["cnt"]) }
        }
    }

    func fetchTopReactions(limit: Int = 10) async throws -> [ReactionCount] {
        try await dbQueue.read { db in
            // Query the likes table (reactions you gave) with canonical emoji mapping.
            // NONE and LIKE both map to 👍 (NONE is the pre-reactions legacy "like").
            // SORRY = old name for SAD, ANGER = old name for ANGRY.
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    CASE reaction_type
                        WHEN 'LIKE'   THEN '👍'
                        WHEN 'NONE'   THEN '👍'
                        WHEN 'LOVE'   THEN '❤️'
                        WHEN 'HAHA'   THEN '😆'
                        WHEN 'WOW'    THEN '😮'
                        WHEN 'SAD'    THEN '😢'
                        WHEN 'SORRY'  THEN '😢'
                        WHEN 'ANGRY'  THEN '😡'
                        WHEN 'ANGER'  THEN '😡'
                        ELSE '👍'
                    END AS emoji,
                    COUNT(*) AS cnt
                FROM likes
                GROUP BY emoji
                ORDER BY cnt DESC
                LIMIT ?
                """, arguments: [limit])
            return rows.map { ReactionCount(emoji: $0["emoji"], count: $0["cnt"]) }
        }
    }

    func fetchPostsPerYear() async throws -> [PostYearBreakdown] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y', timestamp, 'unixepoch') AS year,
                    SUM(CASE WHEN source = 'group' THEN 1 ELSE 0 END) AS group_posts,
                    SUM(CASE WHEN source = 'timeline'
                                  AND (INSTR(COALESCE(title,''), ' wrote on ') > 0
                                    OR INSTR(COALESCE(title,''), ' shared a link to ') > 0)
                             THEN 1 ELSE 0 END) AS wall_posts,
                    SUM(CASE WHEN source = 'timeline'
                                  AND INSTR(COALESCE(title,''), ' wrote on ') = 0
                                  AND INSTR(COALESCE(title,''), ' shared a link to ') = 0
                             THEN 1 ELSE 0 END) AS own_posts
                FROM posts
                GROUP BY year
                ORDER BY year ASC
                """)
            return rows.map {
                PostYearBreakdown(
                    year: $0["year"],
                    ownPosts: $0["own_posts"],
                    wallPosts: $0["wall_posts"],
                    groupPosts: $0["group_posts"]
                )
            }
        }
    }

    func fetchCommentsPerMonth() async throws -> [MonthCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%Y-%m', timestamp, 'unixepoch') AS month, COUNT(*) AS cnt
                FROM comments
                GROUP BY month
                ORDER BY month ASC
                """)
            return rows.map { MonthCount(month: $0["month"], count: $0["cnt"]) }
        }
    }

    func fetchLikesPerMonth() async throws -> [MonthCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%Y-%m', timestamp, 'unixepoch') AS month, COUNT(*) AS cnt
                FROM likes
                WHERE reaction_type = 'LIKE'
                GROUP BY month
                ORDER BY month ASC
                """)
            return rows.map { MonthCount(month: $0["month"], count: $0["cnt"]) }
        }
    }

    func fetchOtherReactionsPerMonth() async throws -> [MonthCount] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT strftime('%Y-%m', timestamp, 'unixepoch') AS month, COUNT(*) AS cnt
                FROM likes
                WHERE reaction_type != 'LIKE'
                GROUP BY month
                ORDER BY month ASC
                """)
            return rows.map { MonthCount(month: $0["month"], count: $0["cnt"]) }
        }
    }

    func fetchTopCommentedOnPeople(limit: Int = 10) async throws -> [CommentEngagement] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT person, COUNT(*) AS cnt
                FROM (
                    SELECT
                        CASE
                            WHEN INSTR(title, ' commented on ') > 0
                              AND INSTR(SUBSTR(title, INSTR(title, ' commented on ') + 14), '''s ') > 0
                                THEN SUBSTR(title,
                                    INSTR(title, ' commented on ') + 14,
                                    INSTR(SUBSTR(title, INSTR(title, ' commented on ') + 14), '''s ') - 1)
                            WHEN INSTR(title, ' replied to ') > 0
                              AND INSTR(SUBSTR(title, INSTR(title, ' replied to ') + 12), '''s ') > 0
                                THEN SUBSTR(title,
                                    INSTR(title, ' replied to ') + 12,
                                    INSTR(SUBSTR(title, INSTR(title, ' replied to ') + 12), '''s ') - 1)
                            ELSE NULL
                        END AS person
                    FROM comments
                )
                WHERE person IS NOT NULL AND person != ''
                GROUP BY person
                ORDER BY cnt DESC
                LIMIT ?
                """, arguments: [limit])
            return rows.map { CommentEngagement(name: $0["person"], count: $0["cnt"]) }
        }
    }

    func fetchTopReactedToPeople(limit: Int = 10) async throws -> [ReactionEngagement] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT person,
                    COUNT(*) AS total,
                    SUM(CASE WHEN reaction_type = 'LIKE'  THEN 1 ELSE 0 END) AS like_count,
                    SUM(CASE WHEN reaction_type = 'LOVE'  THEN 1 ELSE 0 END) AS love_count,
                    SUM(CASE WHEN reaction_type = 'HAHA'  THEN 1 ELSE 0 END) AS haha_count,
                    SUM(CASE WHEN reaction_type = 'WOW'   THEN 1 ELSE 0 END) AS wow_count,
                    SUM(CASE WHEN reaction_type = 'SAD'   THEN 1 ELSE 0 END) AS sad_count,
                    SUM(CASE WHEN reaction_type = 'ANGRY' THEN 1 ELSE 0 END) AS angry_count
                FROM (
                    SELECT reaction_type,
                        CASE
                            WHEN INSTR(title, ' liked ') > 0
                              AND INSTR(SUBSTR(title, INSTR(title, ' liked ') + 7), '''s ') > 0
                                THEN SUBSTR(title,
                                    INSTR(title, ' liked ') + 7,
                                    INSTR(SUBSTR(title, INSTR(title, ' liked ') + 7), '''s ') - 1)
                            WHEN INSTR(title, ' reacted to ') > 0
                              AND INSTR(SUBSTR(title, INSTR(title, ' reacted to ') + 12), '''s ') > 0
                                THEN SUBSTR(title,
                                    INSTR(title, ' reacted to ') + 12,
                                    INSTR(SUBSTR(title, INSTR(title, ' reacted to ') + 12), '''s ') - 1)
                            ELSE NULL
                        END AS person
                    FROM likes
                )
                WHERE person IS NOT NULL AND person != ''
                GROUP BY person
                ORDER BY total DESC
                LIMIT ?
                """, arguments: [limit])
            return rows.map {
                ReactionEngagement(
                    name: $0["person"],
                    total: $0["total"],
                    likeCount: $0["like_count"],
                    loveCount: $0["love_count"],
                    hahaCount: $0["haha_count"],
                    wowCount: $0["wow_count"],
                    sadCount: $0["sad_count"],
                    angryCount: $0["angry_count"]
                )
            }
        }
    }

    func fetchAvgPostLengthPerYear() async throws -> [YearAverage] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y', timestamp, 'unixepoch') AS year,
                    AVG(
                        LENGTH(TRIM(content)) - LENGTH(REPLACE(TRIM(content), ' ', '')) + 1
                    ) AS avg_words
                FROM posts
                WHERE content IS NOT NULL AND TRIM(content) != ''
                GROUP BY year
                ORDER BY year ASC
                """)
            return rows.map { YearAverage(year: $0["year"], value: $0["avg_words"]) }
        }
    }

    func fetchTopThreadsForMonth(isGroup: Bool, limit: Int, userName: String, month: String) async throws -> [ThreadStat] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    t.id, t.title, t.message_count, t.is_group_chat,
                    t.participant_names, t.first_message_at,
                    (
                        SELECT COUNT(*)
                        FROM messages m
                        WHERE m.thread_id = t.id AND m.sender_name = ?
                          AND strftime('%Y-%m', m.timestamp_ms / 1000, 'unixepoch') = ?
                    ) AS my_message_count,
                    (
                        SELECT strftime('%Y', m2.timestamp_ms / 1000, 'unixepoch')
                        FROM messages m2
                        WHERE m2.thread_id = t.id
                        GROUP BY strftime('%Y', m2.timestamp_ms / 1000, 'unixepoch')
                        ORDER BY COUNT(*) DESC
                        LIMIT 1
                    ) AS most_active_year
                FROM threads t
                WHERE t.is_group_chat = ?
                  AND (
                    SELECT COUNT(*)
                    FROM messages m
                    WHERE m.thread_id = t.id
                      AND strftime('%Y-%m', m.timestamp_ms / 1000, 'unixepoch') = ?
                  ) > 0
                ORDER BY my_message_count DESC
                LIMIT ?
                """, arguments: [userName, month, isGroup ? 1 : 0, month, limit])
            return rows.map { row in
                let json: String = row["participant_names"] ?? "[]"
                let names = (try? JSONDecoder().decode(
                    [String].self,
                    from: Data(json.utf8)
                )) ?? []
                return ThreadStat(
                    threadId: row["id"],
                    title: row["title"],
                    messageCount: row["message_count"],
                    myMessageCount: row["my_message_count"] ?? 0,
                    isGroupChat: (row["is_group_chat"] as Int) != 0,
                    participantNames: names,
                    firstMessageAt: row["first_message_at"],
                    mostActiveYear: row["most_active_year"]
                )
            }
        }
    }

    func fetchPostTypeStats() async throws -> PostTypeStats {
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT
                    SUM(CASE WHEN source = 'group' THEN 1 ELSE 0 END) AS group_posts,
                    SUM(CASE WHEN source = 'timeline'
                                  AND (INSTR(COALESCE(title,''), ' wrote on ') > 0
                                    OR INSTR(COALESCE(title,''), ' shared a link to ') > 0)
                             THEN 1 ELSE 0 END) AS wall_posts,
                    SUM(CASE WHEN source = 'timeline'
                                  AND INSTR(COALESCE(title,''), ' wrote on ') = 0
                                  AND INSTR(COALESCE(title,''), ' shared a link to ') = 0
                             THEN 1 ELSE 0 END) AS own_posts
                FROM posts
                """)
            return PostTypeStats(
                ownPosts:   row?["own_posts"]   ?? 0,
                wallPosts:  row?["wall_posts"]  ?? 0,
                groupPosts: row?["group_posts"] ?? 0
            )
        }
    }

    func fetchReactionTypeStats() async throws -> ReactionTypeStats {
        try await dbQueue.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT
                    SUM(CASE WHEN reaction_type IN ('LIKE','NONE') THEN 1 ELSE 0 END) AS like_count,
                    SUM(CASE WHEN reaction_type = 'LOVE'           THEN 1 ELSE 0 END) AS love_count,
                    SUM(CASE WHEN reaction_type = 'HAHA'           THEN 1 ELSE 0 END) AS haha_count,
                    SUM(CASE WHEN reaction_type = 'WOW'            THEN 1 ELSE 0 END) AS wow_count,
                    SUM(CASE WHEN reaction_type IN ('SAD','SORRY')  THEN 1 ELSE 0 END) AS sad_count,
                    SUM(CASE WHEN reaction_type IN ('ANGRY','ANGER') THEN 1 ELSE 0 END) AS angry_count
                FROM likes
                """)
            return ReactionTypeStats(
                likeCount:  row?["like_count"]  ?? 0,
                loveCount:  row?["love_count"]  ?? 0,
                hahaCount:  row?["haha_count"]  ?? 0,
                wowCount:   row?["wow_count"]   ?? 0,
                sadCount:   row?["sad_count"]   ?? 0,
                angryCount: row?["angry_count"] ?? 0
            )
        }
    }

    func fetchAvgMessageLengthPerYear() async throws -> [YearAverage] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    strftime('%Y', timestamp_ms / 1000, 'unixepoch') AS year,
                    AVG(LENGTH(content)) AS avg_len
                FROM messages
                WHERE content IS NOT NULL AND content != ''
                GROUP BY year
                ORDER BY year ASC
                """)
            return rows.map { YearAverage(year: $0["year"], value: $0["avg_len"]) }
        }
    }

    func fetchTopSharedDomains(limit: Int = 15) async throws -> [SharedDomain] {
        let urls = try await dbQueue.read { db in
            try String.fetchAll(db, sql: """
                SELECT share_url FROM messages
                WHERE share_url IS NOT NULL AND share_url != ''
                """)
        }
        var counts: [String: Int] = [:]
        for urlStr in urls {
            if let url = URL(string: urlStr), let host = url.host {
                let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
                counts[domain, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { SharedDomain(domain: $0.key, count: $0.value) }
    }

    func fetchTopTaggedPeople(limit: Int = 10) async throws -> [TaggedPerson] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT name, COUNT(*) AS cnt
                FROM post_tags
                GROUP BY name
                ORDER BY cnt DESC
                LIMIT ?
                """, arguments: [limit])
            return rows.map { TaggedPerson(name: $0["name"], count: $0["cnt"]) }
        }
    }

    func fetchHeatmapData(years: Int = 2) async throws -> [DayCount] {
        let cutoff = Int64(Date().timeIntervalSince1970 - Double(years) * 365.25 * 86400) * 1000
        let cutoffDay = cutoff / 86400000

        return try await dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT
                    (timestamp_ms / 86400000) AS day_key,
                    COUNT(*) AS cnt
                FROM messages
                WHERE (timestamp_ms / 86400000) >= ?
                GROUP BY day_key
                ORDER BY day_key ASC
                """, arguments: [cutoffDay])
            return rows.map { DayCount(dayKey: $0["day_key"], count: $0["cnt"]) }
        }
    }
}
