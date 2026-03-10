import SwiftUI
import GRDB

struct ProfileChangesView: View {
    var viewModel: ProfileChangesViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No Changes" : "No Results",
                    systemImage: viewModel.searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass",
                    description: Text(
                        viewModel.searchText.isEmpty
                            ? "No profile update history found."
                            : "No changes match \"\(viewModel.searchText)\"."
                    )
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        changeRow(item)
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
        .searchable(text: Bindable(viewModel).searchText, prompt: "Filter changes…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
        .navigationTitle("Profile Changes")
    }

    private func changeRow(_ record: ProfileUpdateRecord) -> some View {
        let date = Date(timeIntervalSince1970: Double(record.timestamp))
        let hasImage = record.image_uri != nil
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconForChange(record.title))
                .foregroundStyle(colorForChange(record.title))
                .font(.title3)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.body)
                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let detail = record.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 2)
                }

                if hasImage {
                    profilePictureThumbnail(record)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func profilePictureThumbnail(_ record: ProfileUpdateRecord) -> some View {
        // Photos are stored as {timestamp}.{ext} in profilePhotosDirectory
        let photosDir = DatabaseManager.profilePhotosDirectory
        let ext = record.image_uri.map { URL(fileURLWithPath: $0).pathExtension } ?? "jpg"
        let photoURL = photosDir.appendingPathComponent("\(record.timestamp).\(ext.isEmpty ? "jpg" : ext)")

        return Group {
            if FileManager.default.fileExists(atPath: photoURL.path) {
                LocalImageView(url: photoURL, size: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 4)
            }
        }
    }

    private func iconForChange(_ title: String) -> String {
        let t = title.lowercased()
        if t.contains("profile picture") { return "person.crop.circle" }
        if t.contains("cover photo") { return "photo.artframe" }
        if t.contains("education") { return "graduationcap" }
        if t.contains("work") { return "briefcase" }
        if t.contains("relationship") { return "heart" }
        if t.contains("birthday") { return "birthday.cake" }
        if t.contains("hometown") || t.contains("city") || t.contains("location") { return "mappin.circle" }
        if t.contains("added") { return "plus.circle" }
        if t.contains("changed") || t.contains("edited") || t.contains("updated") { return "pencil.circle" }
        return "arrow.triangle.2.circlepath"
    }

    private func colorForChange(_ title: String) -> Color {
        let t = title.lowercased()
        if t.contains("profile picture") || t.contains("cover photo") { return .purple }
        if t.contains("education") { return .blue }
        if t.contains("work") { return .orange }
        if t.contains("relationship") { return .pink }
        if t.contains("added") { return .green }
        if t.contains("changed") || t.contains("edited") || t.contains("updated") { return .blue }
        return .secondary
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class ProfileChangesViewModel {
    var items: [ProfileUpdateRecord] = []
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
                        conditions.append("title LIKE ?")
                        args.append("%\(currentSearch)%".databaseValue)
                    }

                    let where_ = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
                    let sql = "SELECT * FROM profile_updates \(where_) ORDER BY timestamp DESC LIMIT \(limit)"
                    return try ProfileUpdateRecord.fetchAll(db, sql: sql, arguments: StatementArguments(args))
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
