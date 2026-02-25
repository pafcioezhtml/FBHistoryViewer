import SwiftUI

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    var pipeline: ImportPipeline

    var body: some View {
        VStack(spacing: 20) {
            Text("Importing Data")
                .font(.title2.bold())

            ProgressView(value: pipeline.progress.overallFraction)
                .progressViewStyle(.linear)
                .frame(width: 400)

            // Phase list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(ImportPhase.allCases, id: \.self) { phase in
                    phaseRow(phase)
                }
            }
            .frame(width: 400, alignment: .leading)

            // Stats
            if pipeline.progress.phase != .discovering {
                HStack(spacing: 24) {
                    statLabel("Threads", value: pipeline.progress.totalThreads)
                    statLabel("Messages", value: pipeline.progress.totalMessages)
                    statLabel("Posts", value: pipeline.progress.totalPosts)
                    statLabel("Likes", value: pipeline.progress.totalLikes)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if pipeline.progress.phase == .done {
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            } else if pipeline.isImporting {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(32)
        .frame(minWidth: 480)
    }

    private func phaseRow(_ phase: ImportPhase) -> some View {
        let currentPhase = pipeline.progress.phase
        let isDone = phaseOrder(currentPhase) > phaseOrder(phase)
        let isCurrent = currentPhase == phase

        return HStack(spacing: 10) {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isCurrent {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
            Text(phase.displayName)
                .foregroundStyle(isCurrent ? .primary : (isDone ? .primary : .secondary))
                .fontWeight(isCurrent ? .semibold : .regular)
        }
    }

    private func statLabel(_ label: String, value: Int) -> some View {
        VStack {
            Text("\(value)")
                .font(.headline)
            Text(label)
        }
    }

    private func phaseOrder(_ phase: ImportPhase) -> Int {
        switch phase {
        case .discovering: return 0
        case .messages:    return 1
        case .posts:       return 2
        case .groupPosts:  return 3
        case .likes:       return 4
        case .comments:    return 5
        case .profile:     return 6
        case .finishing:   return 7
        case .done:        return 8
        }
    }
}
