import SwiftUI

enum SidebarItem: Hashable {
    case profile, profileChanges
    case statsOverview, statsMessages, statsPosts, statsActivity, statsFriends, statsLogins, statsSearches, statsMsgReactions
    case feedPosts, feedComments, feedLikes, feedSearches, feedNotifications, feedVisits

    var title: String {
        switch self {
        case .profile:         return "Profile"
        case .profileChanges:  return "Profile Changes"
        case .statsOverview: return "Overview"
        case .statsMessages: return "Messages"
        case .statsPosts:    return "Posts"
        case .statsActivity: return "Activity"
        case .statsFriends:  return "Friends"
        case .statsLogins:   return "Login Activity"
        case .statsSearches: return "Search History"
        case .statsMsgReactions: return "Message Reactions"
        case .feedPosts:     return "Posts"
        case .feedComments:  return "Comments"
        case .feedLikes:     return "Likes"
        case .feedSearches:       return "Recent Searches"
        case .feedNotifications:  return "Recent Notifications"
        case .feedVisits:         return "Recent Visits"
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
    @State private var searchFeedVM   = SearchFeedViewModel()
    @State private var profileChangesVM = ProfileChangesViewModel()
    @State private var notifFeedVM     = NotificationFeedViewModel()
    @State private var visitFeedVM     = VisitFeedViewModel()

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
                searchFeedVM.reload()
                profileChangesVM.reload()
                notifFeedVM.reload()
                visitFeedVM.reload()
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
            case .profileChanges:
                ProfileChangesView(viewModel: profileChangesVM)
            case .statsOverview:
                StatsOverviewView(viewModel: statsVM)
            case .statsMessages:
                StatsMessagesView(viewModel: statsVM)
            case .statsPosts:
                StatsPostsView(viewModel: statsVM)
            case .statsActivity:
                StatsActivityView(viewModel: statsVM)
            case .statsFriends:
                StatsFriendsView(viewModel: statsVM)
            case .statsLogins:
                StatsLoginsView(viewModel: statsVM)
            case .statsSearches:
                StatsSearchesView(viewModel: statsVM)
            case .statsMsgReactions:
                StatsMsgReactionsView(viewModel: statsVM)
            case .feedPosts:
                FeedView(viewModel: feedPostsVM)
            case .feedComments:
                FeedView(viewModel: feedCommentsVM)
            case .feedLikes:
                FeedView(viewModel: feedLikesVM)
            case .feedSearches:
                SearchFeedView(viewModel: searchFeedVM)
            case .feedNotifications:
                NotificationFeedView(viewModel: notifFeedVM)
            case .feedVisits:
                VisitFeedView(viewModel: visitFeedVM)
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(selectedItem?.title ?? "My Social History")
    }
}
