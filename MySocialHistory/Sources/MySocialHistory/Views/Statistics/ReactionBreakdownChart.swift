import SwiftUI
import Charts

struct ReactionBreakdownChart: View {
    let data: [ReactionCount]

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
    }
}
