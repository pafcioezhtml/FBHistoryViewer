import SwiftUI
import AppKit

/// Shown when no data has been imported yet.
/// Immediately opens NSOpenPanel on appear so the user is prompted without
/// having to click anything first.  If they cancel the panel a manual button
/// remains visible.
struct WelcomeView: View {
    @Environment(AppState.self) var appState
    @State private var panelOpened = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("FB History Viewer")
                .font(.largeTitle.bold())

            Text("Select your Facebook data export folder to get started.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button(action: showPicker) {
                Label("Select Facebook Export Folder…", systemImage: "folder.badge.plus")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Divider()
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 8) {
                Text("Accepted folder structures:")
                    .font(.headline)
                Group {
                    bulletRow("The extracted zip folder (e.g. facebook-name-2024-…)")
                    bulletRow("The your_facebook_activity subfolder directly")
                    bulletRow("Any parent folder that contains a Facebook export")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 400, alignment: .leading)
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Open the picker automatically on first appearance
            if !panelOpened {
                panelOpened = true
                // Small delay so the window has time to display
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPicker()
                }
            }
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
        }
    }

    func showPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Facebook Data Export"
        panel.message = "Choose the folder containing your Facebook data export"
        panel.prompt = "Import"
        if panel.runModal() == .OK, let url = panel.url {
            appState.startImport(from: url)
        }
    }
}
