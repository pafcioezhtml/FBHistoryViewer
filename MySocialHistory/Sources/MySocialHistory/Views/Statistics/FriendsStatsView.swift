import SwiftUI
import Charts

// MARK: - Main Friends Stats View

struct StatsFriendsView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading statistics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.loadError {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        FriendsSummaryCard(
                            currentCount: viewModel.friendCount,
                            removedCount: viewModel.removedFriends.count,
                            rejectedCount: viewModel.rejectedRequests.count
                        )
                        FriendsGrowthChart(data: viewModel.friendsPerYear)
                        FriendsAddedPerYearChart(data: viewModel.friendsPerYear)
                        RemovedFriendsView(friends: viewModel.removedFriends)
                        RejectedRequestsView(friends: viewModel.rejectedRequests)
                    }
                    .padding()
                }
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .navigationTitle("Friends")
    }
}

// MARK: - Summary Card

private struct FriendsSummaryCard: View {
    let currentCount: Int
    let removedCount: Int
    let rejectedCount: Int

    var body: some View {
        GroupBox("Friends") {
            HStack(spacing: 0) {
                statCell("Current Friends", value: currentCount, icon: "person.2.fill", color: .blue)
                Divider().frame(height: 50)
                statCell("Removed", value: removedCount, icon: "person.badge.minus", color: .red)
                Divider().frame(height: 50)
                statCell("Rejected", value: rejectedCount, icon: "person.fill.xmark", color: .orange)
                Divider().frame(height: 50)
                statCell("All Time", value: currentCount + removedCount, icon: "person.3.fill", color: .green)
            }
        }
    }

    private func statCell(_ label: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value.formatted(.number))
                .font(.title.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Cumulative Growth Chart

private struct FriendsGrowthChart: View {
    let data: [FriendYearCount]

    var body: some View {
        GroupBox("Friend Count Over Time") {
            if data.isEmpty {
                Text("No friend data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    LineMark(
                        x: .value("Year", item.year),
                        y: .value("Friends", item.cumulative)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Year", item.year),
                        y: .value("Friends", item.cumulative)
                    )
                    .foregroundStyle(Color.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Year", item.year),
                        y: .value("Friends", item.cumulative)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v.formatted(.number))
                            }
                        }
                    }
                }
                .frame(height: 250)
            }
        }
    }
}

// MARK: - New Friends per Year (bar chart)

private struct FriendsAddedPerYearChart: View {
    let data: [FriendYearCount]
    @State private var hoveredYear: String?

    private struct SeriesPoint: Identifiable {
        var id: String { "\(year)-\(kind)" }
        let year: String
        let kind: String
        let count: Int
    }

    private var series: [SeriesPoint] {
        data.flatMap { item in [
            SeriesPoint(year: item.year, kind: "Added", count: item.added),
            SeriesPoint(year: item.year, kind: "Removed", count: item.removed),
        ]}
        .filter { $0.count > 0 }
    }

    private func tooltipForYear(_ year: String) -> some View {
        guard let item = data.first(where: { $0.year == year }) else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(spacing: 2) {
                if item.added > 0 {
                    Text("+\(item.added) added")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                }
                if item.removed > 0 {
                    Text("-\(item.removed) removed")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
        )
    }

    var body: some View {
        GroupBox("Friends Added & Removed per Year") {
            if data.isEmpty {
                Text("No friend data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(series) { point in
                    BarMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(by: .value("Kind", point.kind))
                    .opacity(hoveredYear == nil || hoveredYear == point.year ? 1.0 : 0.3)
                }
                .chartForegroundStyleScale([
                    "Added":   Color.green,
                    "Removed": Color.red.opacity(0.7),
                ])
                .chartLegend(position: .top, alignment: .trailing)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v.formatted(.number))
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    if let plotFrame = proxy.plotFrame {
                                        let plotOrigin = geo[plotFrame].origin
                                        let plotLocation = CGPoint(
                                            x: location.x - plotOrigin.x,
                                            y: location.y - plotOrigin.y
                                        )
                                        if let year: String = proxy.value(atX: plotLocation.x) {
                                            hoveredYear = year
                                        }
                                    }
                                case .ended:
                                    hoveredYear = nil
                                }
                            }
                    }
                }
                .chartOverlay { proxy in
                    if let year = hoveredYear,
                       let plotFrame = proxy.plotFrame {
                        GeometryReader { geo in
                            let pf = geo[plotFrame]
                            if let xPos = proxy.position(forX: year) {
                                tooltipForYear(year)
                                    .position(x: pf.origin.x + xPos, y: pf.origin.y - 4)
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

// MARK: - Removed Friends List

private struct RemovedFriendsView: View {
    let friends: [RemovedFriend]

    var body: some View {
        GroupBox("Removed Friends") {
            if friends.isEmpty {
                Text("No removed friends")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { idx, friend in
                        RemovedFriendRow(friend: friend)
                        if idx < friends.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

private struct RemovedFriendRow: View {
    let friend: RemovedFriend

    var body: some View {
        HStack(spacing: 12) {
            initialsCircle(name: friend.name, size: 36)

            Text(friend.name)
                .font(.headline)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(friend.date, format: .dateTime.year().month(.abbreviated).day())
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

// MARK: - Rejected Requests List

private struct RejectedRequestsView: View {
    let friends: [RemovedFriend]

    var body: some View {
        GroupBox("Rejected Friend Requests") {
            if friends.isEmpty {
                Text("No rejected requests")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(friends.enumerated()), id: \.element.id) { idx, friend in
                        RemovedFriendRow(friend: friend)
                        if idx < friends.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private func initialsCircle(name: String, size: CGFloat) -> some View {
    let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    let initials: String
    if words.count >= 2 {
        initials = (words[0].first.map(String.init) ?? "") +
                   (words[1].first.map(String.init) ?? "")
    } else {
        initials = String(name.prefix(2)).uppercased()
    }

    var hash = 5381
    for scalar in name.unicodeScalars {
        hash = (hash &* 33) &+ Int(scalar.value)
    }
    let hue = Double(abs(hash) % 360) / 360.0
    let color = Color(hue: hue, saturation: 0.55, brightness: 0.72)

    return Circle()
        .fill(color)
        .frame(width: size, height: size)
        .overlay {
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
}
