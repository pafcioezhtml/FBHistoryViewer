import SwiftUI
import GRDB

struct VisitFeedView: View {
    var viewModel: VisitFeedViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VisitCategory.allCases) { cat in
                        categoryTab(cat)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()

            // Content
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        viewModel.searchText.isEmpty ? "No Visits" : "No Results",
                        systemImage: viewModel.searchText.isEmpty
                            ? viewModel.selectedCategory.icon
                            : "magnifyingglass",
                        description: Text(
                            viewModel.searchText.isEmpty
                                ? "No \(viewModel.selectedCategory.displayName.lowercased()) visit history found."
                                : "No visits match \"\(viewModel.searchText)\"."
                        )
                    )
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            visitRow(item)
                                .listRowInsets(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
                        }

                        if viewModel.hasMore {
                            HStack {
                                Spacer()
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                } else {
                                    Button("Load More") { viewModel.loadNextPage() }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                            .onAppear { viewModel.loadNextPage() }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
        .searchable(text: Bindable(viewModel).searchText, prompt: "Filter visits…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
        .navigationTitle("Recent Visits")
    }

    private func categoryTab(_ cat: VisitCategory) -> some View {
        let isSelected = viewModel.selectedCategory == cat
        return Button {
            viewModel.selectedCategory = cat
        } label: {
            HStack(spacing: 4) {
                Image(systemName: cat.icon)
                    .font(.caption)
                Text(cat.displayName)
                    .font(.caption.weight(.medium))
                if let count = viewModel.categoryCounts[cat.rawValue], count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? cat.color.opacity(0.15) : Color.clear)
            .foregroundStyle(isSelected ? cat.color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? cat.color.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func visitRow(_ record: VisitRecord) -> some View {
        let cat = VisitCategory(rawValue: record.category) ?? .events
        let date = record.timestamp > 0
            ? Date(timeIntervalSince1970: Double(record.timestamp))
            : nil

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text(cat.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(cat.color)
                } icon: {
                    Image(systemName: cat.icon)
                        .foregroundStyle(cat.color)
                        .font(.caption)
                }

                Spacer()

                if let date {
                    Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(record.name)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class VisitFeedViewModel {
    var items: [VisitRecord] = []
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
    var selectedCategory: VisitCategory = .events {
        didSet {
            if oldValue != selectedCategory { loadInitial() }
        }
    }
    var categoryCounts: [String: Int] = [:]
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var hasMore: Bool = true

    private let pageSize = 50
    private var lastTimestamp: Int64?
    private var lastId: Int64?
    private var searchTask: Task<Void, Never>?
    private let dbQueue: DatabaseQueue

    init() {
        dbQueue = DatabaseManager.shared.dbQueue
        loadCategoryCounts()
    }

    func loadInitial() {
        items = []
        lastTimestamp = nil
        lastId = nil
        hasMore = true
        load(isInitial: true)
    }

    func reload() {
        loadCategoryCounts()
        loadInitial()
    }

    func loadNextPage() {
        guard hasMore, !isLoadingMore else { return }
        load(isInitial: false)
    }

    private func loadCategoryCounts() {
        Task { @MainActor in
            do {
                let result: [String: Int] = try await dbQueue.read { db in
                    let rows = try Row.fetchAll(db, sql: "SELECT category, COUNT(*) as cnt FROM visits GROUP BY category")
                    var map: [String: Int] = [:]
                    for row in rows {
                        map[row["category"] as String] = row["cnt"] as Int
                    }
                    return map
                }
                categoryCounts = result
            } catch {}
        }
    }

    private func load(isInitial: Bool) {
        if isInitial { isLoading = true } else { isLoadingMore = true }

        let cursor = lastTimestamp
        let cursorId = lastId
        let currentSearch = searchText
        let limit = pageSize
        let cat = selectedCategory.rawValue

        Task { @MainActor in
            defer {
                isLoading = false
                isLoadingMore = false
            }
            do {
                let page = try await dbQueue.read { db in
                    var conditions: [String] = ["category = ?"]
                    var args: [DatabaseValue] = [cat.databaseValue]

                    if let ts = cursor, let cid = cursorId {
                        conditions.append("(timestamp < ? OR (timestamp = ? AND id < ?))")
                        args.append(ts.databaseValue)
                        args.append(ts.databaseValue)
                        args.append(cid.databaseValue)
                    }
                    if !currentSearch.isEmpty {
                        conditions.append("name LIKE ?")
                        args.append("%\(currentSearch)%".databaseValue)
                    }

                    let where_ = "WHERE " + conditions.joined(separator: " AND ")
                    let sql = "SELECT * FROM visits \(where_) ORDER BY timestamp DESC, id DESC LIMIT \(limit)"
                    return try VisitRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
                }
                if isInitial {
                    items = page
                } else {
                    items.append(contentsOf: page)
                }
                if let last = page.last {
                    lastTimestamp = last.timestamp
                    lastId = last.id
                }
                hasMore = page.count == limit
            } catch {}
        }
    }
}
