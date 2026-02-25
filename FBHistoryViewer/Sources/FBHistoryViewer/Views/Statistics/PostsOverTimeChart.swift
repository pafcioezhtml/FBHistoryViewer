import SwiftUI
import Charts

// MARK: - Tagged People

struct TaggedPeopleView: View {
    let people: [TaggedPerson]

    var body: some View {
        GroupBox("Most Frequently Tagged in Posts") {
            if people.isEmpty {
                Text("No tag data — re-import to enable")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(people.enumerated()), id: \.element.id) { idx, person in
                        TaggedPersonRow(person: person, rank: idx + 1)
                        if idx < people.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

private struct TaggedPersonRow: View {
    let person: TaggedPerson
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            tagCircle(name: person.name, size: 36)

            Text(person.name)
                .font(.headline)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(person.count.formatted(.number))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text(person.count == 1 ? "tag" : "tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

private func tagCircle(name: String, size: CGFloat) -> some View {
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

struct PostLengthChart: View {
    let data: [YearAverage]

    var body: some View {
        GroupBox("Average Post Length per Year (words)") {
            if data.isEmpty {
                Text("No post data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Year", item.year),
                        y: .value("Words", item.value)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .annotation(position: .top, alignment: .center) {
                        Text(item.value, format: .number.precision(.fractionLength(0...1)))
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

struct PostsOverTimeChart: View {
    let data: [PostYearBreakdown]

    // Flat series for Swift Charts stacked bars
    private struct SeriesPoint: Identifiable {
        var id: String { "\(year)-\(kind)" }
        let year: String
        let kind: String
        let count: Int
    }

    private var series: [SeriesPoint] {
        data.flatMap { item in [
            SeriesPoint(year: item.year, kind: "Posts",       count: item.ownPosts),
            SeriesPoint(year: item.year, kind: "Wall Posts",  count: item.wallPosts),
            SeriesPoint(year: item.year, kind: "Group Posts", count: item.groupPosts),
        ]}
    }

    var body: some View {
        GroupBox("Posts per Year") {
            if data.isEmpty {
                Text("No post data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(series) { point in
                    BarMark(
                        x: .value("Year", point.year),
                        y: .value("Posts", point.count)
                    )
                    .foregroundStyle(by: .value("Kind", point.kind))
                }
                .chartForegroundStyleScale([
                    "Posts":       Color.teal,
                    "Wall Posts":  Color.orange,
                    "Group Posts": Color.purple,
                ])
                .chartLegend(position: .top, alignment: .trailing)
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
                .frame(height: 220)
                Label("Post/Wall classification requires English Facebook interface", systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}
