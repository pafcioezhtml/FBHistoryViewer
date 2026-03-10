import Foundation
import Observation

@Observable
@MainActor
final class StatisticsViewModel {
    var overview: OverviewStats = OverviewStats()
    var postTypeStats: PostTypeStats = PostTypeStats()
    var reactionTypeStats: ReactionTypeStats = ReactionTypeStats()
    var messagesPerMonth: [MonthCount] = []
    var topIndividualThreads: [ThreadStat] = []
    var topGroupThreads: [ThreadStat] = []
    var activityByHour: [HourCount] = []
    var activityByWeekday: [WeekdayCount] = []
    var topReactions: [ReactionCount] = []
    var postsPerYear: [PostYearBreakdown] = []
    var avgPostLengthPerYear: [YearAverage] = []
    var commentsPerMonth: [MonthCount] = []
    var likesPerMonth: [MonthCount] = []
    var otherReactionsPerMonth: [MonthCount] = []
    var topCommentedOnPeople: [CommentEngagement] = []
    var topReactedToPeople: [ReactionEngagement] = []
    var topTaggedPeople: [TaggedPerson] = []
    var avgMessageLengthPerYear: [YearAverage] = []
    var topSharedDomains: [SharedDomain] = []
    var friendsPerYear: [FriendYearCount] = []
    var removedFriends: [RemovedFriend] = []
    var rejectedRequests: [RemovedFriend] = []
    var friendCount: Int = 0
    var loginsPerMonth: [MonthCount] = []
    var loginDevices: [DeviceCount] = []
    var loginCities: [CityCount] = []
    var loginCount: Int = 0
    var loginByHour: [HourCount] = []
    var searchesPerMonth: [MonthCount] = []
    var topSearchQueries: [TopSearchQuery] = []
    var searchCount: Int = 0
    var searchByHour: [HourCount] = []
    var msgReactionsPerMonth: [MsgReactionMonthCount] = []
    var mostEmotionalIndividual: [EmotionalThread] = []
    var mostEmotionalGroup: [EmotionalThread] = []
    var msgReactionCount: Int = 0
    var topMsgReactionEmojis: [MsgReactionEmojiCount] = []

    var userName: String = ""
    var isLoading: Bool = false
    var loadError: String?

    private var loaded = false
    private let repository: StatisticsRepository

    init() {
        repository = StatisticsRepository(dbQueue: DatabaseManager.shared.dbQueue)
    }

    func loadIfNeeded() {
        guard !loaded else { return }
        load()
    }

    func reload() {
        loaded = false
        load()
    }

    private func load() {
        isLoading = true
        loadError = nil
        Task { @MainActor in
            do {
                // Fetch user name first — needed to count "my messages" per thread
                let uName = (try? await repository.fetchUserName()) ?? ""
                userName = uName

                async let ov   = repository.fetchOverviewStats()
                async let pts  = repository.fetchPostTypeStats()
                async let rts  = repository.fetchReactionTypeStats()
                async let mpm  = repository.fetchMessagesPerMonth(userName: uName)
                async let tc   = repository.fetchTopThreads(isGroup: false, limit: 20, userName: uName)
                async let tcg  = repository.fetchTopThreads(isGroup: true, limit: 10, userName: uName)
                async let abh  = repository.fetchActivityByHour()
                async let abwd = repository.fetchActivityByWeekday()
                async let tr   = repository.fetchTopReactions()
                async let ppy  = repository.fetchPostsPerYear()
                async let apl  = repository.fetchAvgPostLengthPerYear()
                async let cpm  = repository.fetchCommentsPerMonth()
                async let lpm  = repository.fetchLikesPerMonth()
                async let orm  = repository.fetchOtherReactionsPerMonth()
                async let tcp  = repository.fetchTopCommentedOnPeople()
                async let trp  = repository.fetchTopReactedToPeople()
                async let ttp  = repository.fetchTopTaggedPeople()
                async let aml  = repository.fetchAvgMessageLengthPerYear()
                async let tsd  = repository.fetchTopSharedDomains()
                async let fpy  = repository.fetchFriendsPerYear()
                async let rmf  = repository.fetchRemovedFriends()
                async let rjr  = repository.fetchRejectedRequests()
                async let fc   = repository.fetchFriendCount()
                async let lpm2 = repository.fetchLoginsPerMonth()
                async let ld   = repository.fetchLoginDevices()
                async let lc2  = repository.fetchLoginCities()
                async let lct  = repository.fetchLoginCount()
                async let lbh  = repository.fetchLoginByHour()
                async let spm  = repository.fetchSearchesPerMonth()
                async let tsq  = repository.fetchTopSearchQueries()
                async let sct  = repository.fetchSearchCount()
                async let sbh  = repository.fetchSearchByHour()
                async let mrpm = repository.fetchMsgReactionsPerMonth()
                async let mei  = repository.fetchMostEmotionalThreads(userName: uName, isGroup: false)
                async let meg  = repository.fetchMostEmotionalThreads(userName: uName, isGroup: true)
                async let mrc  = repository.fetchMsgReactionCount()
                async let tmre = repository.fetchTopMsgReactionEmojis()

                overview          = try await ov
                postTypeStats     = try await pts
                reactionTypeStats = try await rts
                messagesPerMonth = try await mpm
                topIndividualThreads = try await tc
                topGroupThreads      = try await tcg
                activityByHour   = try await abh
                activityByWeekday = try await abwd
                topReactions     = try await tr
                postsPerYear         = try await ppy
                avgPostLengthPerYear = try await apl
                commentsPerMonth       = try await cpm
                likesPerMonth         = try await lpm
                otherReactionsPerMonth = try await orm
                topCommentedOnPeople = try await tcp
                topReactedToPeople   = try await trp
                topTaggedPeople          = try await ttp
                avgMessageLengthPerYear  = try await aml
                topSharedDomains         = try await tsd
                friendsPerYear           = try await fpy
                removedFriends           = try await rmf
                rejectedRequests         = try await rjr
                friendCount              = try await fc
                loginsPerMonth           = try await lpm2
                loginDevices             = try await ld
                loginCities              = try await lc2
                loginCount               = try await lct
                loginByHour              = try await lbh
                searchesPerMonth         = try await spm
                topSearchQueries         = try await tsq
                searchCount              = try await sct
                searchByHour             = try await sbh
                msgReactionsPerMonth     = try await mrpm
                mostEmotionalIndividual  = try await mei
                mostEmotionalGroup       = try await meg
                msgReactionCount         = try await mrc
                topMsgReactionEmojis     = try await tmre
                loaded = true
            } catch {
                loadError = error.localizedDescription
            }
            isLoading = false
        }
    }
}
