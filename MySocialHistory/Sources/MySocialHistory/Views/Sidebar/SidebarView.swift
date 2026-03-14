import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @Environment(AppState.self) var appState

    var body: some View {
        List(selection: $selectedItem) {
            Section("You") {
                Label("Profile", systemImage: "person.circle.fill")
                    .tag(SidebarItem.profile)
                Label("Changes", systemImage: "clock.arrow.circlepath")
                    .tag(SidebarItem.profileChanges)
            }
            Section("Statistics") {
                Label("Overview", systemImage: "chart.pie.fill")
                    .tag(SidebarItem.statsOverview)
                Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                    .tag(SidebarItem.statsMessages)
                Label("Message Reactions", systemImage: "face.smiling")
                    .tag(SidebarItem.statsMsgReactions)
                Label("Posts", systemImage: "doc.text.fill")
                    .tag(SidebarItem.statsPosts)
                Label("Activity", systemImage: "calendar.badge.clock")
                    .tag(SidebarItem.statsActivity)
                Label("Friends", systemImage: "person.2.fill")
                    .tag(SidebarItem.statsFriends)
                Label("Login Activity", systemImage: "lock.shield.fill")
                    .tag(SidebarItem.statsLogins)
                Label("Search History", systemImage: "magnifyingglass")
                    .tag(SidebarItem.statsSearches)
            }
            Section("Activity Feed") {
                Label("Posts", systemImage: "doc.text.fill")
                    .tag(SidebarItem.feedPosts)
                Label("Comments", systemImage: "text.bubble.fill")
                    .tag(SidebarItem.feedComments)
                Label("Likes", systemImage: "hand.thumbsup.fill")
                    .tag(SidebarItem.feedLikes)
                Label("Recent Searches", systemImage: "magnifyingglass")
                    .tag(SidebarItem.feedSearches)
                Label("Recent Notifications", systemImage: "bell.fill")
                    .tag(SidebarItem.feedNotifications)
                Label("Recent Visits", systemImage: "mappin.and.ellipse")
                    .tag(SidebarItem.feedVisits)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("My Social History")
    }

}
