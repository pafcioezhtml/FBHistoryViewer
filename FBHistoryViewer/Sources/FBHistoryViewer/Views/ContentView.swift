import SwiftUI

enum SidebarItem: Hashable {
    case profile
    case statsOverview, statsMessages, statsPosts, statsActivity
    case feedPosts, feedComments, feedLikes

    var title: String {
        switch self {
        case .profile:       return "Profile"
        case .statsOverview: return "Overview"
        case .statsMessages: return "Messages"
        case .statsPosts:    return "Posts"
        case .statsActivity: return "Activity"
        case .feedPosts:     return "Posts"
        case .feedComments:  return "Comments"
        case .feedLikes:     return "Likes"
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) var appState
    @State private var selectedItem: SidebarItem? = .statsOverview
    @State private var profileVM      = ProfileViewModel()
    @State private var statsVM        = StatisticsViewModel()
    @State private var feedPostsVM    = FeedViewModel(filter: .posts)
    @State private var feedCommentsVM = FeedViewModel(filter: .comments)
    @State private var feedLikesVM    = FeedViewModel(filter: .likes)

    var body: some View {
        Group {
            if appState.hasImportedData {
                mainContent
            } else {
                WelcomeView()
            }
        }
        .sheet(isPresented: Bindable(appState).showingImport) {
            if let pipeline = appState.importPipeline {
                ImportView(pipeline: pipeline)
            }
        }
        .onChange(of: appState.showingImport) { _, showing in
            if !showing {
                profileVM.reload()
                statsVM.reload()
                feedPostsVM.reload()
                feedCommentsVM.reload()
                feedLikesVM.reload()
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { appState.importError != nil },
            set: { if !$0 { appState.importError = nil } }
        )) {
            Button("OK") { appState.importError = nil }
        } message: {
            Text(appState.importError ?? "")
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
            case .profile:
                ProfileView(viewModel: profileVM)
            case .statsOverview:
                StatsOverviewView(viewModel: statsVM)
            case .statsMessages:
                StatsMessagesView(viewModel: statsVM)
            case .statsPosts:
                StatsPostsView(viewModel: statsVM)
            case .statsActivity:
                StatsActivityView(viewModel: statsVM)
            case .feedPosts:
                FeedView(viewModel: feedPostsVM)
            case .feedComments:
                FeedView(viewModel: feedCommentsVM)
            case .feedLikes:
                FeedView(viewModel: feedLikesVM)
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(selectedItem?.title ?? "FB History Viewer")
    }
}
