import SwiftUI
import Charts

struct StatsMsgReactionsView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading statistics…")
                        .padding(40)
                } else if let error = viewModel.loadError {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    MsgReactionSummaryCard(
                        totalReactions: viewModel.msgReactionCount,
                        topEmojis: viewModel.topMsgReactionEmojis
                    )
                    MsgReactionsOverTimeChart(data: viewModel.msgReactionsPerMonth)
                    TopMsgReactionEmojisChart(data: viewModel.topMsgReactionEmojis)
                    MostEmotionalConversationsView(
                        title: "Most Emotional — Individual",
                        icon: "person.fill",
                        iconColor: .blue,
                        threads: viewModel.mostEmotionalIndividual
                    )
                    MostEmotionalConversationsView(
                        title: "Most Emotional — Group Chats",
                        icon: "person.3.fill",
                        iconColor: .purple,
                        threads: viewModel.mostEmotionalGroup
                    )
                }
            }
            .padding()
        }
        .onAppear { viewModel.loadIfNeeded() }
        .navigationTitle("Message Reactions")
    }
}

// MARK: - Summary Card

private struct MsgReactionSummaryCard: View {
    let totalReactions: Int
    let topEmojis: [MsgReactionEmojiCount]

    var body: some View {
        VStack(spacing: 12) {
            Text("Message Reactions")
                .font(.headline)

            HStack(spacing: 0) {
                summaryCell(
                    icon: "face.smiling",
                    color: .orange,
                    value: "\(totalReactions)",
                    label: "Total Reactions"
                )

                if let top = topEmojis.first {
                    Divider().frame(height: 40)
                    summaryCell(
                        icon: nil,
                        emoji: top.emoji,
                        color: .pink,
                        value: "\(top.count)",
                        label: "Most Used"
                    )
                }

                if topEmojis.count >= 2 {
                    Divider().frame(height: 40)
                    summaryCell(
                        icon: nil,
                        emoji: topEmojis[1].emoji,
                        color: .blue,
                        value: "\(topEmojis[1].count)",
                        label: "2nd Most Used"
                    )
                }

                if topEmojis.count >= 3 {
                    Divider().frame(height: 40)
                    summaryCell(
                        icon: nil,
                        emoji: topEmojis[2].emoji,
                        color: .purple,
                        value: "\(topEmojis[2].count)",
                        label: "3rd Most Used"
                    )
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .copyable()
    }

    private func summaryCell(icon: String? = nil, emoji: String? = nil, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            if let emoji {
                Text(emoji)
                    .font(.title2)
            } else if let icon {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
            }
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reactions Over Time Chart

private struct MsgReactionsOverTimeChart: View {
    let data: [MsgReactionMonthCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reactions Over Time")
                .font(.headline)

            if data.isEmpty {
                Text("No reaction data available.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(data) { item in
                    AreaMark(
                        x: .value("Month", item.date),
                        y: .value("Reactions", item.count)
                    )
                    .foregroundStyle(.orange.opacity(0.3))

                    LineMark(
                        x: .value("Month", item.date),
                        y: .value("Reactions", item.count)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .year)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.year())
                    }
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .copyable()
    }
}

// MARK: - Top Reaction Emojis Chart (Donut)

private struct TopMsgReactionEmojisChart: View {
    let data: [MsgReactionEmojiCount]

    var body: some View {
        GroupBox("Reaction Breakdown") {
            if data.isEmpty {
                Text("No reaction data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                HStack(alignment: .top, spacing: 24) {
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Emoji", item.emoji))
                        .annotation(position: .overlay) {
                            Text(item.emoji)
                                .font(.title3)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: 200, height: 200)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data) { item in
                            HStack {
                                Text(item.emoji)
                                Text(item.count, format: .number)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .font(.callout)
                        }
                    }
                    .frame(maxHeight: 200, alignment: .top)
                }
            }
        }
        .copyable()
    }
}

// MARK: - Most Emotional Conversations

private struct MostEmotionalConversationsView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let threads: [EmotionalThread]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }
            Text("Ranked by your reactions per 100 messages (min. 100 messages)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if threads.isEmpty {
                Text("No data available.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(threads.enumerated()), id: \.element.id) { index, thread in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(thread.title)
                                .font(.body)
                                .lineLimit(1)
                            HStack(spacing: 8) {
                                Text("\(thread.messageCount) msgs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(thread.reactionCount) my reactions")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f", thread.reactionsPer100))
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                            Text("per 100 msgs")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if index < threads.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .copyable()
    }
}
