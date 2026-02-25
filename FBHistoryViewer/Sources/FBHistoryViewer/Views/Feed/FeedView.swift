import SwiftUI

struct FeedView: View {
    var viewModel: FeedViewModel

    var body: some View {
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
        .searchable(text: Bindable(viewModel).searchText, prompt: "Search…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
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
