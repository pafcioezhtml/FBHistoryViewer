import SwiftUI

struct PostFeedItemView: View {
    let record: PostRecord

    private var date: Date {
        Date(timeIntervalSince1970: Double(record.timestamp))
    }

    /// Extracts the wall owner's name if this post was written on someone else's profile.
    /// Handles: "X wrote on [Name]'s profile." and "X shared a link to [Name]'s timeline."
    private var wallOwner: String? {
        guard let title = record.title else { return nil }
        let patterns: [(search: String, end: String)] = [
            (" wrote on ", "'s profile"),
            (" shared a link to ", "'s timeline"),
        ]
        for (search, end) in patterns {
            if let start = title.range(of: search),
               let endRange = title.range(of: end, range: start.upperBound..<title.endIndex) {
                return String(title[start.upperBound..<endRange.lowerBound])
            }
        }
        return nil
    }

    private var postKind: (label: String, icon: String) {
        if record.source == "group"  { return ("Group Post", "person.3.fill") }
        if wallOwner != nil          { return ("Wall Post",  "person.fill.viewfinder") }
        return ("Post", "doc.text.fill")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                let kind = postKind
                Label {
                    Text(kind.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                } icon: {
                    Image(systemName: kind.icon)
                        .foregroundStyle(.teal)
                        .font(.caption)
                }

                Spacer()

                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let owner = wallOwner {
                Text("on \(owner)'s profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let groupName = record.group_name {
                Text("in \(groupName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let content = record.content, !content.isEmpty {
                Text(content)
                    .font(.body)
            } else if let title = record.title, wallOwner == nil {
                // Suppress title for wall posts — the "on X's profile" line already says it
                Text(title)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let url = record.external_url {
                Link(url, destination: URL(string: url) ?? URL(string: "about:blank")!)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if record.has_media {
                Label("Contains media", systemImage: "photo")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
