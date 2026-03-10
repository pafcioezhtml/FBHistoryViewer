import SwiftUI
import Charts

struct StatsSearchesView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SearchSummaryCard(viewModel: viewModel)
                SearchFrequencyChart(data: viewModel.searchesPerMonth)
                SearchByHourChart(data: viewModel.searchByHour)
                TopSearchQueriesView(data: viewModel.topSearchQueries)
            }
            .padding()
        }
        .onAppear { viewModel.loadIfNeeded() }
    }
}

// MARK: - Summary Card

private struct SearchSummaryCard: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        GroupBox("Search History") {
            HStack(spacing: 0) {
                statCell("Total Searches", value: "\(viewModel.searchCount.formatted(.number))",
                         icon: "magnifyingglass", color: .orange)
                Divider().frame(height: 50)
                statCell("Since",
                         value: viewModel.searchesPerMonth.first?.month ?? "—",
                         icon: "calendar", color: .blue)
                Divider().frame(height: 50)
                if viewModel.searchCount > 0, viewModel.searchesPerMonth.count > 0 {
                    let avg = Double(viewModel.searchCount) / Double(viewModel.searchesPerMonth.count)
                    statCell("Avg/Month", value: String(format: "%.1f", avg),
                             icon: "chart.line.uptrend.xyaxis", color: .green)
                    Divider().frame(height: 50)
                }
                statCell("Unique Queries", value: "\(viewModel.topSearchQueries.count)",
                         icon: "text.magnifyingglass", color: .purple)
            }
        }
    }

    private func statCell(_ label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Search Frequency Chart

private struct SearchFrequencyChart: View {
    let data: [MonthCount]

    var body: some View {
        GroupBox("Searches per Month") {
            if data.isEmpty {
                Text("No data").foregroundStyle(.secondary).frame(height: 200)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Searches", item.count)
                    )
                    .foregroundStyle(.orange.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

// MARK: - Search by Hour

private struct SearchByHourChart: View {
    let data: [HourCount]

    var body: some View {
        GroupBox("Searches by Hour of Day") {
            if data.isEmpty {
                Text("No data").foregroundStyle(.secondary).frame(height: 200)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Searches", item.count)
                    )
                    .foregroundStyle(.orange.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let h = value.as(Int.self) {
                                Text("\(h):00")
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Top Queries

private struct TopSearchQueriesView: View {
    let data: [TopSearchQuery]

    var body: some View {
        GroupBox("Top Searched Terms") {
            if data.isEmpty {
                Text("No data").foregroundStyle(.secondary)
            } else {
                let maxCount = data.first?.count ?? 1
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(data) { item in
                        HStack(spacing: 8) {
                            Text(item.query)
                                .lineLimit(1)
                                .frame(width: 200, alignment: .leading)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.orange.gradient)
                                    .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                            }
                            .frame(height: 18)
                            Text("\(item.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }
}
