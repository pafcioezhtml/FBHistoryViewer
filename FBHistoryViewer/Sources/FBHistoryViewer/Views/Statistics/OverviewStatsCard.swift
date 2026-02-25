import SwiftUI

struct OverviewStatsCard: View {
    let stats: OverviewStats

    var body: some View {
        GroupBox("Overview") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                statCell(label: "Threads",    value: stats.threadCount,   icon: "bubble.left.and.bubble.right", color: .blue)
                statCell(label: "Messages",   value: stats.messageCount,  icon: "message.fill",                color: .blue)
                statCell(label: "Msg Reactions", value: stats.reactionCount, icon: "heart.fill",                  color: .blue)
                statCell(label: "Posts",            value: stats.postCount,     icon: "doc.text.fill",               color: .blue)
                statCell(label: "Reactions Given", value: stats.likeCount,     icon: "hand.thumbsup.fill",          color: .blue)
                statCell(label: "Comments",        value: stats.commentCount,  icon: "text.bubble.fill",            color: .blue)
            }
            .padding(.top, 4)
        }
    }

    private func statCell(label: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value, format: .number)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Posts Breakdown

struct PostsBreakdownCard: View {
    let stats: PostTypeStats

    var body: some View {
        GroupBox("Posts") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                postCell(label: "Your Posts",   value: stats.ownPosts,   color: .teal)
                postCell(label: "Wall Posts",   value: stats.wallPosts,  color: .orange)
                postCell(label: "Group Posts",  value: stats.groupPosts, color: .purple)
            }
            .padding(.top, 4)
            englishOnlyNote
        }
    }

    private var englishOnlyNote: some View {
        Label("Classification requires English Facebook interface", systemImage: "info.circle")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
    }

    private func postCell(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value, format: .number)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Reactions Breakdown

struct ReactionsBreakdownCard: View {
    let stats: ReactionTypeStats

    private struct Entry: Identifiable {
        var id: String { emoji }
        let emoji: String
        let label: String
        let count: Int
    }

    private var entries: [Entry] {
        [
            Entry(emoji: "👍", label: "Like",  count: stats.likeCount),
            Entry(emoji: "❤️", label: "Love",  count: stats.loveCount),
            Entry(emoji: "😆", label: "Haha",  count: stats.hahaCount),
            Entry(emoji: "😮", label: "Wow",   count: stats.wowCount),
            Entry(emoji: "😢", label: "Sad",   count: stats.sadCount),
            Entry(emoji: "😡", label: "Angry", count: stats.angryCount),
        ]
    }

    var body: some View {
        GroupBox("Reactions Given") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(entries) { entry in
                    reactionCell(entry: entry)
                }
            }
            .padding(.top, 4)
        }
    }

    private func reactionCell(entry: Entry) -> some View {
        VStack(spacing: 4) {
            Text(entry.emoji)
                .font(.title2)
            Text(entry.count, format: .number)
                .font(.title3.bold())
                .monospacedDigit()
            Text(entry.label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }
}
