import SwiftUI

struct FeedView: View {
    var viewModel: FeedViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.filter == .posts {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PostSubFilter.allCases) { sub in
                            postSubTab(sub)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                Divider()
            }

            Group {
                if viewModel.isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        viewModel.searchText.isEmpty ? "No Activity" : "No Results",
                        systemImage: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(
                            viewModel.searchText.isEmpty
                                ? "Nothing here yet."
                                : "No items match \"\(viewModel.searchText)\"."
                        )
                    )
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            feedRow(item)
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
        .searchable(text: Bindable(viewModel).searchText, prompt: "Search…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
    }

    private func postSubTab(_ sub: PostSubFilter) -> some View {
        let isSelected = viewModel.postSubFilter == sub
        return Button {
            viewModel.postSubFilter = sub
        } label: {
            HStack(spacing: 4) {
                Image(systemName: sub.icon)
                    .font(.caption)
                Text(sub.displayName)
                    .font(.caption.weight(.medium))
                if let count = viewModel.postSubCounts[sub.rawValue], count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? sub.color.opacity(0.15) : Color.clear)
            .foregroundStyle(isSelected ? sub.color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? sub.color.opacity(0.5) : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func feedRow(_ item: FeedItem) -> some View {
        switch item {
        case .post(let r):    PostFeedItemView(record: r)
        case .like(let r):    LikeFeedItemView(record: r)
        case .comment(let r): CommentFeedItemView(record: r)
        }
    }
}
