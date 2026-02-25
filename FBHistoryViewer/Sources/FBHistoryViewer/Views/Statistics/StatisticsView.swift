import SwiftUI

// Shared loading/error wrapper used by all 4 stats sub-views
private struct StatsPage<Content: View>: View {
    let viewModel: StatisticsViewModel
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading statistics…")
                        .padding(40)
                } else if let error = viewModel.loadError {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    content()
                }
            }
            .padding()
        }
        .onAppear { viewModel.loadIfNeeded() }
    }
}

// MARK: - Overview

struct StatsOverviewView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        StatsPage(viewModel: viewModel) {
            OverviewStatsCard(stats: viewModel.overview)
            PostsBreakdownCard(stats: viewModel.postTypeStats)
            ReactionsBreakdownCard(stats: viewModel.reactionTypeStats)
        }
        .navigationTitle("Overview")
    }
}

// MARK: - Messages

struct StatsMessagesView: View {
    var viewModel: StatisticsViewModel
    @State private var selectedThreadId: Int64?
    @State private var overlayData: [MonthCount] = []
    @State private var hoveredMonth: String?
    @State private var monthIndividualThreads: [ThreadStat]?
    @State private var monthGroupThreads: [ThreadStat]?
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading statistics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.loadError {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                VStack(spacing: 0) {
                    MessagesOverTimeChart(
                        data: viewModel.messagesPerMonth,
                        overlay: overlayData,
                        hoveredMonth: $hoveredMonth
                    )
                    .padding()
                    Divider()
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            TopConversationsView(
                                individual: monthIndividualThreads ?? viewModel.topIndividualThreads,
                                groups: monthGroupThreads ?? viewModel.topGroupThreads,
                                selectedThreadId: $selectedThreadId,
                                period: hoveredMonth
                            )
                            MessageLengthOverTimeChart(data: viewModel.avgMessageLengthPerYear)
                            SharedDomainsView(domains: viewModel.topSharedDomains)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .onChange(of: selectedThreadId) { _, newId in
            guard let id = newId else { overlayData = []; return }
            let userName = viewModel.userName
            Task {
                let repo = StatisticsRepository(dbQueue: DatabaseManager.shared.dbQueue)
                overlayData = (try? await repo.fetchMessagesPerMonth(threadId: id, userName: userName)) ?? []
            }
        }
        .onChange(of: hoveredMonth) { _, newMonth in
            hoverTask?.cancel()
            guard let month = newMonth else {
                monthIndividualThreads = nil
                monthGroupThreads = nil
                return
            }
            let userName = viewModel.userName
            hoverTask = Task {
                let repo = StatisticsRepository(dbQueue: DatabaseManager.shared.dbQueue)
                async let ind = repo.fetchTopThreadsForMonth(isGroup: false, limit: 20, userName: userName, month: month)
                async let grp = repo.fetchTopThreadsForMonth(isGroup: true, limit: 10, userName: userName, month: month)
                guard !Task.isCancelled else { return }
                if let results = try? await (ind, grp), !Task.isCancelled {
                    monthIndividualThreads = results.0
                    monthGroupThreads = results.1
                }
            }
        }
        .navigationTitle("Messages")
    }
}

// MARK: - Posts

struct StatsPostsView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        StatsPage(viewModel: viewModel) {
            PostsOverTimeChart(data: viewModel.postsPerYear)
            PostLengthChart(data: viewModel.avgPostLengthPerYear)
            TaggedPeopleView(people: viewModel.topTaggedPeople)
        }
        .navigationTitle("Posts")
    }
}

// MARK: - Activity

struct StatsActivityView: View {
    var viewModel: StatisticsViewModel

    var body: some View {
        StatsPage(viewModel: viewModel) {
            CommentsPerMonthChart(data: viewModel.commentsPerMonth)
            ReactionsPerMonthChart(
                likes: viewModel.likesPerMonth,
                others: viewModel.otherReactionsPerMonth
            )
            ActivityByHourChart(data: viewModel.activityByHour)
            ActivityByWeekdayChart(data: viewModel.activityByWeekday)
            ReactionBreakdownChart(data: viewModel.topReactions)
            EngagementListsView(
                commentedOn: viewModel.topCommentedOnPeople,
                reactedTo: viewModel.topReactedToPeople
            )
        }
        .navigationTitle("Activity")
    }
}
