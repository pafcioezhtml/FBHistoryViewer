import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @Environment(AppState.self) var appState

    var body: some View {
        List(selection: $selectedItem) {
            Section("You") {
                Label("Profile", systemImage: "person.circle.fill")
                    .tag(SidebarItem.profile)
            }
            Section("Statistics") {
                Label("Overview", systemImage: "chart.pie.fill")
                    .tag(SidebarItem.statsOverview)
                Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                    .tag(SidebarItem.statsMessages)
                Label("Posts", systemImage: "doc.text.fill")
                    .tag(SidebarItem.statsPosts)
                Label("Activity", systemImage: "calendar.badge.clock")
                    .tag(SidebarItem.statsActivity)
            }
            Section("Activity Feed") {
                Label("Posts", systemImage: "doc.text.fill")
                    .tag(SidebarItem.feedPosts)
                Label("Comments", systemImage: "text.bubble.fill")
                    .tag(SidebarItem.feedComments)
                Label("Likes", systemImage: "hand.thumbsup.fill")
                    .tag(SidebarItem.feedLikes)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("FB History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImportPicker()
                } label: {
                    Label("Re-import", systemImage: "arrow.clockwise")
                }
                .help("Import a new Facebook data export")
            }
        }
    }

    private func showImportPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your Facebook data export folder"
        panel.prompt = "Import"
        if panel.runModal() == .OK, let url = panel.url {
            appState.startImport(from: url)
        }
    }
}
