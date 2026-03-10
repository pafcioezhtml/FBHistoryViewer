import SwiftUI
import GRDB

struct NotificationFeedView: View {
    var viewModel: NotificationFeedViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No Notifications" : "No Results",
                    systemImage: viewModel.searchText.isEmpty ? "bell" : "magnifyingglass",
                    description: Text(
                        viewModel.searchText.isEmpty
                            ? "No notification history found."
                            : "No notifications match \"\(viewModel.searchText)\"."
                    )
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        notificationRow(item)
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
        .searchable(text: Bindable(viewModel).searchText, prompt: "Filter notifications…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
        .navigationTitle("Notifications")
    }

    private func notificationRow(_ record: NotificationRecord) -> some View {
        let date = Date(timeIntervalSince1970: Double(record.timestamp))
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconForNotification(record.text))
                .foregroundStyle(colorForNotification(record.text))
                .font(.title3)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .font(.body)
                    .opacity(record.unread ? 1.0 : 0.8)
                Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if record.unread {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 2)
    }

    private func iconForNotification(_ text: String) -> String {
        let t = text.lowercased()
        if t.contains("birthday") { return "birthday.cake" }
        if t.contains("event") { return "calendar" }
        if t.contains("friend request") { return "person.badge.plus" }
        if t.contains("commented") || t.contains("comment") { return "text.bubble" }
        if t.contains("reacted") || t.contains("liked") { return "hand.thumbsup" }
        if t.contains("tagged") || t.contains("mentioned") { return "at" }
        if t.contains("shared") || t.contains("posted") { return "square.and.arrow.up" }
        if t.contains("group") { return "person.3" }
        if t.contains("memory") || t.contains("memories") { return "clock.arrow.circlepath" }
        if t.contains("reel") || t.contains("video") { return "play.rectangle" }
        return "bell"
    }

    private func colorForNotification(_ text: String) -> Color {
        let t = text.lowercased()
        if t.contains("birthday") { return .pink }
        if t.contains("event") { return .orange }
        if t.contains("friend request") { return .green }
        if t.contains("commented") || t.contains("comment") { return .indigo }
        if t.contains("reacted") || t.contains("liked") { return .blue }
        if t.contains("tagged") || t.contains("mentioned") { return .purple }
        if t.contains("group") { return .teal }
        return .secondary
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class NotificationFeedViewModel {
    var items: [NotificationRecord] = []
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

    func reload() { loadInitial() }

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
                        conditions.append("text LIKE ?")
                        args.append("%\(currentSearch)%".databaseValue)
                    }

                    let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
                    let sql = "SELECT * FROM notifications \(where_) ORDER BY timestamp DESC LIMIT \(limit)"
                    return try NotificationRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
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
