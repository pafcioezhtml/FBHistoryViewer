import SwiftUI

struct CommentFeedItemView: View {
    let record: CommentRecord

    private var date: Date {
        Date(timeIntervalSince1970: Double(record.timestamp))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label {
                    Text("Comment")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                } icon: {
                    Image(systemName: "text.bubble.fill")
                        .foregroundStyle(.indigo)
                        .font(.caption)
                }

                Spacer()

                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let title = record.title, !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let text = record.comment_text, !text.isEmpty {
                Text(text)
                    .font(.body)
            }
        }
        .padding(.vertical, 2)
    }
}
