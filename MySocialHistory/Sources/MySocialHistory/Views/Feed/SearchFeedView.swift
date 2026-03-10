import SwiftUI

struct SearchFeedView: View {
    var viewModel: SearchFeedViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    viewModel.searchText.isEmpty ? "No Searches" : "No Results",
                    systemImage: viewModel.searchText.isEmpty ? "magnifyingglass" : "magnifyingglass",
                    description: Text(
                        viewModel.searchText.isEmpty
                            ? "No search history found."
                            : "No searches match \"\(viewModel.searchText)\"."
                    )
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        searchRow(item)
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
        .searchable(text: Bindable(viewModel).searchText, prompt: "Filter searches…")
        .onAppear {
            if viewModel.items.isEmpty { viewModel.loadInitial() }
        }
    }

    private func searchRow(_ record: SearchRecord) -> some View {
        let date = Date(timeIntervalSince1970: Double(record.timestamp))
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text("Search")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                } icon: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }

                Spacer()

                Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(record.query)
                .font(.body)

            if !record.title.isEmpty && record.title != "You searched Facebook" {
                Text(record.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
