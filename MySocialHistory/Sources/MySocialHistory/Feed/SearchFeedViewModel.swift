import Foundation
import Observation
import GRDB

@Observable
@MainActor
final class SearchFeedViewModel {
    var items: [SearchRecord] = []
    var searchText: String = "" {
        didSet {
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                loadInitial()
            }
        }
    }
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var hasMore: Bool = true

    private let pageSize = 50
    private var lastTimestamp: Int64?
    private var searchTask: Task<Void, Never>?
    private let dbQueue: DatabaseQueue

    init() {
        dbQueue = DatabaseManager.shared.dbQueue
    }

    func loadInitial() {
        items = []
        lastTimestamp = nil
        hasMore = true
        load(isInitial: true)
    }

    func reload() {
        loadInitial()
    }

    func loadNextPage() {
        guard hasMore, !isLoadingMore else { return }
        load(isInitial: false)
    }

    private func load(isInitial: Bool) {
        if isInitial { isLoading = true } else { isLoadingMore = true }

        let cursor = lastTimestamp
        let currentSearch = searchText
        let limit = pageSize

        Task { @MainActor in
            defer {
                isLoading = false
                isLoadingMore = false
            }
            do {
                let page = try await dbQueue.read { db in
                    var conditions: [String] = []
                    var args: [DatabaseValue] = []

                    if let ts = cursor {
                        conditions.append("timestamp < ?")
                        args.append(ts.databaseValue)
                    }
                    if !currentSearch.isEmpty {
                        conditions.append("query LIKE ?")
                        args.append("%\(currentSearch)%".databaseValue)
                    }

                    let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
                    let sql = "SELECT * FROM searches \(where_) ORDER BY timestamp DESC LIMIT \(limit)"
                    return try SearchRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
                }
                if isInitial {
                    items = page
                } else {
                    items.append(contentsOf: page)
                }
                lastTimestamp = page.last?.timestamp
                hasMore = page.count == limit
            } catch {
                // silently handle
            }
        }
    }
}
