import Foundation
import Observation

@Observable
@MainActor
final class FeedViewModel {
    var items: [FeedItem] = []
    var filter: FeedFilter = .posts {
        didSet { reload() }
    }
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
    var loadError: String?

    private var lastTimestamp: Int64?
    private var searchTask: Task<Void, Never>?
    private let repository: FeedRepository

    init(filter: FeedFilter = .posts) {
        self.filter = filter
        repository = FeedRepository(dbQueue: DatabaseManager.shared.dbQueue)
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
        if isInitial {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        loadError = nil

        let cursor = lastTimestamp
        let currentFilter = filter
        let currentSearch = searchText

        Task { @MainActor in
            defer {
                isLoading = false
                isLoadingMore = false
            }
            do {
                let page = try await repository.fetchPage(
                    beforeTimestamp: cursor,
                    filter: currentFilter,
                    searchText: currentSearch
                )
                if isInitial {
                    items = page
                } else {
                    items.append(contentsOf: page)
                }
                lastTimestamp = page.last?.timestamp
                hasMore = page.count == repository.pageSize
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}
