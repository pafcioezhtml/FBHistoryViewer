import SwiftUI

struct ActivityHeatmapView: View {
    let data: [DayCount]
    private let weeks = 52 * 2    // 2 years
    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 2

    private var dayMap: [Int64: Int] {
        Dictionary(uniqueKeysWithValues: data.map { ($0.dayKey, $0.count) })
    }

    private var maxCount: Int {
        data.map(\.count).max() ?? 1
    }

    private var startDay: Int64 {
        let todayKey = Int64(Date().timeIntervalSince1970) / 86400
        return todayKey - Int64(weeks * 7) + 1
    }

    var body: some View {
        GroupBox("Activity Heatmap (last 2 years)") {
            if data.isEmpty {
                Text("No message data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(0..<weeks, id: \.self) { weekOffset in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { dayOfWeek in
                                    let dayKey = startDay + Int64(weekOffset * 7 + dayOfWeek)
                                    let count = dayMap[dayKey] ?? 0
                                    cell(count: count)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: CGFloat(7) * (cellSize + cellSpacing) + 16)

                legendRow
            }
        }
    }

    private func cell(count: Int) -> some View {
        let intensity = count == 0 ? 0.0 : Double(count) / Double(max(maxCount, 1))
        return RoundedRectangle(cornerRadius: 2)
            .fill(cellColor(intensity: intensity))
            .frame(width: cellSize, height: cellSize)
    }

    private func cellColor(intensity: Double) -> Color {
        if intensity == 0 { return Color(.separatorColor) }
        return Color.green.opacity(0.3 + intensity * 0.7)
    }

    private var legendRow: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                cellColor(intensity: v)
                    .frame(width: cellSize, height: cellSize)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
