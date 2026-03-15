import SwiftUI

// MARK: - Focused Value Keys

struct ToggleHelpKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowExportGuideKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var toggleHelp: Binding<Bool>? {
        get { self[ToggleHelpKey.self] }
        set { self[ToggleHelpKey.self] = newValue }
    }

    var showExportGuide: Binding<Bool>? {
        get { self[ShowExportGuideKey.self] }
        set { self[ShowExportGuideKey.self] = newValue }
    }
}

// MARK: - Help Menu Commands

struct HelpCommands: Commands {
    @FocusedValue(\.toggleHelp) var toggleHelp
    @FocusedValue(\.showExportGuide) var showExportGuide

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("My Social History Help") {
                if let binding = toggleHelp {
                    withAnimation { binding.wrappedValue = true }
                }
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Button("How to Export Facebook Data") {
                showExportGuide?.wrappedValue = true
            }
        }
    }
}

// MARK: - Facebook Export Guide

struct FacebookExportGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    steps
                    tipsSection
                }
                .padding(30)
            }
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 520, height: 560)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text("How to Export Your Facebook Data")
                    .font(.title2.bold())
            }
            Text("Facebook lets you download a copy of your data. Follow these steps to get the export that works with My Social History.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepRow(number: 1,
                    title: "Open Facebook Settings",
                    detail: "Go to facebook.com, click your profile picture (top-right), then Settings & privacy \u{2192} Settings.")

            stepRow(number: 2,
                    title: "Go to \"Your Facebook information\"",
                    detail: "In the left sidebar, click \"Your Facebook information\", then \"Download your information\".")

            stepRow(number: 3,
                    title: "Request a download",
                    detail: "Click \"Request a download\". Select the data you want (or select all). Choose:")

            exportSettings

            stepRow(number: 4,
                    title: "Wait for the export",
                    detail: "Facebook will prepare your data. This can take minutes to hours depending on the amount. You'll get a notification when it's ready.")

            stepRow(number: 5,
                    title: "Download and extract",
                    detail: "Download the zip file(s) from the \"Available files\" tab. Extract (unzip) them to a folder on your Mac.")

            stepRow(number: 6,
                    title: "Import into My Social History",
                    detail: "Open My Social History, click \"Re-import data\", and select the extracted folder. The app will find and import all supported data automatically.")
        }
    }

    private var exportSettings: some View {
        VStack(alignment: .leading, spacing: 6) {
            settingRow(label: "Format:", value: "JSON", important: true)
            settingRow(label: "Media quality:", value: "Low (saves time \u{2014} media is not imported)")
            settingRow(label: "Date range:", value: "All time")
        }
        .padding(.leading, 36)
        .padding(.vertical, 4)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                tipRow("You can import multiple exports into the same app \u{2014} just point to a parent folder containing all extracted exports.")
                tipRow("Only JSON format is supported. HTML exports won't work.")
                tipRow("The app reads messages, posts, comments, reactions, friends, logins, searches, visits, and profile data.")
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Row helpers

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.callout.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.bold())
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func settingRow(label: String, value: String, important: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.bold())
                .foregroundStyle(important ? .blue : .primary)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\u{2022}")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
