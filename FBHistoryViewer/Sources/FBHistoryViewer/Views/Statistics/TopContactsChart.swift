import SwiftUI

// MARK: - Top Conversations View

struct TopConversationsView: View {
    let individual: [ThreadStat]
    let groups: [ThreadStat]
    @Binding var selectedThreadId: Int64?
    var period: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            if !individual.isEmpty {
                conversationSection(title: "Individual Conversations", threads: individual)
            }
            if !groups.isEmpty {
                conversationSection(title: "Group Conversations", threads: groups)
            }
            if individual.isEmpty && groups.isEmpty {
                GroupBox {
                    Text(period != nil ? "No messages in this month" : "No conversation data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
    }

    private func conversationSection(title: String, threads: [ThreadStat]) -> some View {
        let sectionTitle = period.map { "\(title) — \(formattedPeriod($0))" } ?? title
        return GroupBox(sectionTitle) {
            VStack(spacing: 0) {
                ForEach(Array(threads.enumerated()), id: \.element.id) { idx, thread in
                    ConversationRow(
                        thread: thread,
                        rank: idx + 1,
                        isSelected: selectedThreadId == thread.threadId
                    ) {
                        selectedThreadId = selectedThreadId == thread.threadId ? nil : thread.threadId
                    }
                    if idx < threads.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
        }
    }

    private func formattedPeriod(_ month: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        fmt.locale = Locale(identifier: "en_US")
        guard let date = fmt.date(from: month) else { return month }
        let display = DateFormatter()
        display.dateFormat = "MMMM yyyy"
        display.locale = Locale(identifier: "en_US")
        return display.string(from: date)
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let thread: ThreadStat
    let rank: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            avatarView
                .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(thread.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    if let date = thread.firstExchangeDate {
                        statChip(
                            icon: "calendar",
                            text: date.formatted(.dateTime.month(.abbreviated).year())
                        )
                    }
                    if let year = thread.mostActiveYear {
                        statChip(icon: "star.fill", text: "Peak \(year)")
                    }
                    if thread.isGroupChat {
                        statChip(
                            icon: "person.2.fill",
                            text: "\(thread.participantNames.count) members"
                        )
                    }
                }
            }

            Spacer(minLength: 8)

            // Message counts
            VStack(alignment: .trailing, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(thread.myMessageCount.formatted(.number.notation(.compactName)))
                        .font(.title3.bold())
                    Text("me")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(thread.messageCount.formatted(.number.notation(.compactName)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("total")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func statChip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Avatars

    @ViewBuilder
    private var avatarView: some View {
        if thread.isGroupChat {
            groupAvatar
        } else {
            initialsCircle(name: thread.title, size: 44)
        }
    }

    private var groupAvatar: some View {
        let names = Array(thread.participantNames.prefix(3))
        return ZStack {
            ForEach(Array(names.enumerated().reversed()), id: \.offset) { idx, name in
                initialsCircle(name: name, size: 26)
                    .overlay(Circle().stroke(Color(NSColor.windowBackgroundColor), lineWidth: 2))
                    .offset(groupOffset(idx: idx, total: names.count))
            }
        }
    }

    private func groupOffset(idx: Int, total: Int) -> CGSize {
        switch total {
        case 1:
            return .zero
        case 2:
            return idx == 0 ? CGSize(width: -9, height: 0) : CGSize(width: 9, height: 0)
        default:
            switch idx {
            case 0: return CGSize(width: -11, height: -9)
            case 1: return CGSize(width: 11, height: -9)
            default: return CGSize(width: 0, height: 9)
            }
        }
    }

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
}
