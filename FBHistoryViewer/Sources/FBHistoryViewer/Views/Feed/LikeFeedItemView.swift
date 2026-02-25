import SwiftUI

struct LikeFeedItemView: View {
    let record: LikeRecord

    private var date: Date {
        Date(timeIntervalSince1970: Double(record.timestamp))
    }

    private var reactionEmoji: String {
        switch record.reaction_type.uppercased() {
        case "LIKE":  return "👍"
        case "LOVE":  return "❤️"
        case "HAHA":  return "😆"
        case "WOW":   return "😮"
        case "SAD":   return "😢"
        case "ANGRY": return "😡"
        default:      return "👍"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(reactionEmoji)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.body)

                HStack(spacing: 6) {
                    Text(record.reaction_type.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
