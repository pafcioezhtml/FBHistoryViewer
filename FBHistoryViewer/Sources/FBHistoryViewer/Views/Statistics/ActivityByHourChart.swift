import SwiftUI
import Charts

struct ActivityByHourChart: View {
    let data: [HourCount]

    // Fill in missing hours with zero
    private var fullData: [HourCount] {
        let existing = Dictionary(uniqueKeysWithValues: data.map { ($0.hour, $0.count) })
        return (0..<24).map { h in HourCount(hour: h, count: existing[h] ?? 0) }
    }

    var body: some View {
        GroupBox("Activity by Hour of Day") {
            if data.isEmpty {
                emptyState
            } else {
                Chart(fullData) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Messages", item.count)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let h = value.as(Int.self) {
                                Text(hourLabel(h))
                            }
                        }
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

    private func hourLabel(_ h: Int) -> String {
        h == 0 ? "12am" : h < 12 ? "\(h)am" : h == 12 ? "12pm" : "\(h - 12)pm"
    }

    private var emptyState: some View {
        Text("No message data")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
    }
}

// MARK: - Weekday

struct ActivityByWeekdayChart: View {
    let data: [WeekdayCount]

    // Mon–Sun display order (SQLite: 0=Sun … 6=Sat)
    private static let order = [1, 2, 3, 4, 5, 6, 0]
    private static let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var orderedData: [(label: String, count: Int)] {
        let existing = Dictionary(uniqueKeysWithValues: data.map { ($0.weekday, $0.count) })
        return zip(Self.order, Self.labels).map { (weekday, label) in
            (label: label, count: existing[weekday] ?? 0)
        }
    }

    var body: some View {
        GroupBox("Activity by Day of Week") {
            if data.isEmpty {
                Text("No message data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(orderedData, id: \.label) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Messages", item.count)
                    )
                    .foregroundStyle(.teal.gradient)
                    .cornerRadius(3)
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
