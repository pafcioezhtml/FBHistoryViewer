import SwiftUI

struct EngagementListsView: View {
    let commentedOn: [CommentEngagement]
    let reactedTo: [ReactionEngagement]

    var body: some View {
        VStack(spacing: 16) {
            commentedOnSection
            reactedToSection
        }
    }

    // MARK: - Commented On

    private var commentedOnSection: some View {
        GroupBox("People You Commented On Most") {
            if commentedOn.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(commentedOn.enumerated()), id: \.element.id) { idx, item in
                        CommentEngagementRow(item: item, rank: idx + 1)
                        if idx < commentedOn.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            englishOnlyNote
        }
    }

    // MARK: - Reacted To

    private var reactedToSection: some View {
        GroupBox("People Whose Content You Reacted To Most") {
            if reactedTo.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reactedTo.enumerated()), id: \.element.id) { idx, item in
                        ReactionEngagementRow(item: item, rank: idx + 1)
                        if idx < reactedTo.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            englishOnlyNote
        }
    }

    private var englishOnlyNote: some View {
        Label("Requires English Facebook interface to extract names", systemImage: "info.circle")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
    }

    private var emptyState: some View {
        Text("No data")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60)
    }
}

// MARK: - Comment Row

private struct CommentEngagementRow: View {
    let item: CommentEngagement
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            initialsCircle(name: item.name, size: 40)

            Text(item.name)
                .font(.headline)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(item.count.formatted(.number))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("comments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

// MARK: - Reaction Row

private struct ReactionEngagementRow: View {
    let item: ReactionEngagement
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            initialsCircle(name: item.name, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    ForEach(item.breakdown, id: \.emoji) { entry in
                        HStack(spacing: 2) {
                            Text(entry.emoji)
                                .font(.caption)
                            Text("\(entry.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(item.total.formatted(.number))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

// MARK: - Shared Helpers

private func initialsCircle(name: String, size: CGFloat) -> some View {
    Circle()
        .fill(deterministicColor(for: name))
        .frame(width: size, height: size)
        .overlay {
            Text(initials(for: name))
                .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
}

private func initials(for name: String) -> String {
    let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    if words.count >= 2 {
        return (words[0].first.map(String.init) ?? "") +
               (words[1].first.map(String.init) ?? "")
    }
    return String(name.prefix(2)).uppercased()
}

private func deterministicColor(for name: String) -> Color {
    var hash = 5381
    for scalar in name.unicodeScalars {
        hash = (hash &* 33) &+ Int(scalar.value)
    }
    let hue = Double(abs(hash) % 360) / 360.0
    return Color(hue: hue, saturation: 0.55, brightness: 0.72)
}
