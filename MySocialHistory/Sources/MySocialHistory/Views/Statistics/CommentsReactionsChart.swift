import SwiftUI
import Charts

// MARK: - Comments per Month

struct CommentsPerMonthChart: View {
    let data: [MonthCount]

    var body: some View {
        GroupBox("Comments per Month") {
            if data.isEmpty {
                Text("No comment data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Month", item.date, unit: .month),
                        y: .value("Comments", item.count)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .year)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.year())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v, format: .number.notation(.compactName))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }
}

// MARK: - Reactions per Month (Likes vs Others)

struct ReactionsPerMonthChart: View {
    let likes: [MonthCount]
    let others: [MonthCount]

    private struct Point: Identifiable {
        var id: String { "\(month)-\(kind)" }
        let month: String
        let kind: String
        let count: Int
        var date: Date {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM"
            return fmt.date(from: month) ?? Date()
        }
    }

    private var series: [Point] {
        likes.map  { Point(month: $0.month, kind: "👍 Likes",  count: $0.count) } +
        others.map { Point(month: $0.month, kind: "❤️ Others", count: $0.count) }
    }

    var body: some View {
        GroupBox("Reactions per Month") {
            if series.isEmpty {
                Text("No reaction data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(series) { point in
                    BarMark(
                        x: .value("Month", point.date, unit: .month),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(by: .value("Kind", point.kind))
                    .position(by: .value("Kind", point.kind), axis: .horizontal)
                }
                .chartForegroundStyleScale([
                    "👍 Likes":  Color.orange,
                    "❤️ Others": Color.pink,
                ])
                .chartLegend(position: .top, alignment: .trailing)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .year)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.year())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v, format: .number.notation(.compactName))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }
}
