import SwiftUI
import Charts

// MARK: - Average Message Length per Year

struct MessageLengthOverTimeChart: View {
    let data: [YearAverage]

    var body: some View {
        GroupBox("Average Message Length per Year (characters)") {
            if data.isEmpty {
                Text("No message data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    LineMark(
                        x: .value("Year", item.year),
                        y: .value("Chars", item.value)
                    )
                    .foregroundStyle(Color.indigo.gradient)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Year", item.year),
                        y: .value("Chars", item.value)
                    )
                    .foregroundStyle(Color.indigo.opacity(0.12).gradient)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Year", item.year),
                        y: .value("Chars", item.value)
                    )
                    .foregroundStyle(Color.indigo)
                    .symbolSize(30)
                    .annotation(position: .top, alignment: .center) {
                        Text(item.value, format: .number.precision(.fractionLength(0...0)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v, format: .number.notation(.compactName))
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

// MARK: - Top Shared Domains

struct SharedDomainsView: View {
    let domains: [SharedDomain]

    private var maxCount: Int { domains.first?.count ?? 1 }

    var body: some View {
        GroupBox("Most Shared Domains") {
            if domains.isEmpty {
                Text("No shared links")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(domains.enumerated()), id: \.element.id) { idx, item in
                        SharedDomainRow(item: item, rank: idx + 1, maxCount: maxCount)
                        if idx < domains.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }
}

private struct SharedDomainRow: View {
    let item: SharedDomain
    let rank: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .trailing)

            Text(item.domain)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 8)

            // Mini bar
            GeometryReader { geo in
                let w = geo.size.width * CGFloat(item.count) / CGFloat(maxCount)
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cyan.opacity(0.6))
                        .frame(width: max(4, w))
                    Spacer(minLength: 0)
                }
            }
            .frame(width: 80, height: 12)

            Text(item.count.formatted(.number))
                .font(.callout.bold())
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
    }
}
