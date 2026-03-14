import SwiftUI

// MARK: - Help Sidebar Panel

struct HelpSidebar: View {
    let item: SidebarItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let item {
                    helpHeader(item)
                    helpBody(item)
                } else {
                    Text("Select a section to see help.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func helpHeader(_ item: SidebarItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(item.iconColor)
            Text(item.title)
                .font(.title3.bold())
        }
        Divider()
    }

    // MARK: - Body

    @ViewBuilder
    private func helpBody(_ item: SidebarItem) -> some View {
        let sections = item.helpSections
        ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
            if let heading = section.heading {
                Text(heading)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Text(section.body)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Help Data Model

struct HelpSection {
    let heading: String?
    let body: String
}

// MARK: - SidebarItem Help Extensions

extension SidebarItem {
    var icon: String {
        switch self {
        case .profile:          return "person.circle.fill"
        case .profileChanges:   return "clock.arrow.circlepath"
        case .statsOverview:    return "chart.pie.fill"
        case .statsMessages:    return "bubble.left.and.bubble.right.fill"
        case .statsMsgReactions: return "face.smiling"
        case .statsPosts:       return "doc.text.fill"
        case .statsActivity:    return "calendar.badge.clock"
        case .statsFriends:     return "person.2.fill"
        case .statsLogins:      return "lock.shield.fill"
        case .statsSearches:    return "magnifyingglass"
        case .feedPosts:        return "doc.text.fill"
        case .feedComments:     return "text.bubble.fill"
        case .feedLikes:        return "hand.thumbsup.fill"
        case .feedSearches:     return "magnifyingglass"
        case .feedNotifications: return "bell.fill"
        case .feedVisits:       return "mappin.and.ellipse"
        }
    }

    var iconColor: Color {
        switch self {
        case .profile, .profileChanges:               return .blue
        case .statsOverview:                           return .purple
        case .statsMessages:                           return .blue
        case .statsMsgReactions:                       return .orange
        case .statsPosts:                              return .teal
        case .statsActivity:                           return .indigo
        case .statsFriends:                            return .green
        case .statsLogins:                             return .blue
        case .statsSearches:                           return .orange
        case .feedPosts:                               return .teal
        case .feedComments:                            return .indigo
        case .feedLikes:                               return .orange
        case .feedSearches:                            return .orange
        case .feedNotifications:                       return .red
        case .feedVisits:                              return .green
        }
    }

    var helpSections: [HelpSection] {
        switch self {

        // MARK: Profile

        case .profile:
            return [
                HelpSection(heading: nil, body: "Your Facebook profile information as it appeared in the data export, including your name, bio, and other details you've added to your profile."),
            ]

        case .profileChanges:
            return [
                HelpSection(heading: nil, body: "A timeline of changes you've made to your Facebook profile \u{2014} name changes, bio updates, and other profile modifications \u{2014} shown in chronological order."),
            ]

        // MARK: Statistics

        case .statsOverview:
            return [
                HelpSection(heading: nil, body: "A summary dashboard with key metrics from your entire Facebook history at a glance."),
                HelpSection(heading: "Overview", body: "Total counts for threads, messages, reactions, posts, comments, and friends."),
                HelpSection(heading: "Posts Breakdown", body: "Your posts split into three categories: your own posts, posts on others' walls, and group posts. Classification requires that your Facebook interface was set to English."),
                HelpSection(heading: "Reactions Given", body: "A breakdown of every reaction type you've used (Like, Love, Haha, Wow, Sad, Angry) with counts for each."),
            ]

        case .statsMessages:
            return [
                HelpSection(heading: nil, body: "An interactive view of your messaging history over time."),
                HelpSection(heading: "Messages Over Time", body: "A bar chart showing your message volume per month across your entire history. Hover over a month to see who you talked to most during that period."),
                HelpSection(heading: "Top Conversations", body: "Your most active conversations, split into individual chats and group chats. Click any conversation to overlay its message volume on the main chart. When hovering a month, the list updates to show top contacts for that specific period."),
                HelpSection(heading: "Message Length", body: "How your average message length (in characters) has changed year by year. A rising trend might mean you shifted from quick replies to longer messages."),
                HelpSection(heading: "Shared Domains", body: "The websites and domains you've shared most frequently in your messages, ranked by link count."),
            ]

        case .statsMsgReactions:
            return [
                HelpSection(heading: nil, body: "Analytics for emoji reactions within your message conversations (the small emoji reactions on individual messages, not post reactions)."),
                HelpSection(heading: "Summary", body: "Total reaction count and the top three most-used reaction emojis."),
                HelpSection(heading: "Reactions Over Time", body: "Monthly trend of how many message reactions you exchanged. A rising line suggests conversations became more expressive over time."),
                HelpSection(heading: "Reaction Breakdown", body: "A donut chart showing the proportion of each emoji used as a message reaction."),
                HelpSection(heading: "Most Emotional Conversations", body: "Conversations ranked by reactions per 100 messages (minimum 100 messages). Split into individual and group chats. A high score means the conversation was particularly expressive."),
            ]

        case .statsPosts:
            return [
                HelpSection(heading: nil, body: "Insights into your posting behavior on Facebook over the years."),
                HelpSection(heading: "Posts per Year", body: "A stacked bar chart showing your own posts, wall posts, and group posts by year. See how your posting habits shifted over time."),
                HelpSection(heading: "Average Post Length", body: "Your average post length in words, per year. Shows whether you tended toward short status updates or longer-form writing."),
                HelpSection(heading: "Tagged People", body: "The people you tagged most frequently in your posts, ranked by tag count."),
            ]

        case .statsActivity:
            return [
                HelpSection(heading: nil, body: "Your commenting, reacting, and engagement patterns across Facebook."),
                HelpSection(heading: "Comments per Month", body: "How many comments you left on posts each month."),
                HelpSection(heading: "Reactions per Month", body: "Your reactions (likes and other types) over time, shown as grouped bars so you can see the balance between simple likes and other reactions."),
                HelpSection(heading: "Activity by Hour / Day", body: "When you were most active on Facebook. The hour chart reveals your daily rhythm; the weekday chart shows which days you engaged most."),
                HelpSection(heading: "Reaction Breakdown", body: "A donut chart of all reaction types you've ever used, showing your overall reaction style."),
                HelpSection(heading: "Engagement Lists", body: "The people whose content you commented on and reacted to most frequently. Requires English Facebook interface for name extraction."),
            ]

        case .statsFriends:
            return [
                HelpSection(heading: nil, body: "The evolution of your Facebook friend list over time."),
                HelpSection(heading: "Friend Count Over Time", body: "A cumulative growth chart showing your total friend count at the end of each year."),
                HelpSection(heading: "Added & Removed per Year", body: "How many friends you added and removed each year. Hover over a year to see the exact numbers. Useful for spotting periods of social expansion or cleanup."),
                HelpSection(heading: "Removed Friends", body: "People who were removed from your friend list, with the date of removal."),
                HelpSection(heading: "Rejected Requests", body: "Friend requests you declined, with dates."),
            ]

        case .statsLogins:
            return [
                HelpSection(heading: nil, body: "Details about your Facebook login sessions, devices, and locations."),
                HelpSection(heading: "Summary", body: "Total login sessions, number of distinct devices, and your most-used device."),
                HelpSection(heading: "Sessions Over Time", body: "Monthly count of login sessions. Gaps may indicate periods when you were less active or stayed logged in."),
                HelpSection(heading: "Sessions by Hour", body: "What time of day you typically logged in. Peaks usually align with morning routines or evening browsing."),
                HelpSection(heading: "Device Breakdown", body: "A donut chart showing the proportion of sessions from each device (iPhone, Mac, Windows, etc.)."),
                HelpSection(heading: "Login Locations", body: "A map and list of cities from which you logged in, with session counts. Locations are geocoded from city names in your export."),
            ]

        case .statsSearches:
            return [
                HelpSection(heading: nil, body: "Your Facebook search activity: what you searched for, how often, and when."),
                HelpSection(heading: "Summary", body: "Total searches, the date range, average searches per month, and count of unique queries."),
                HelpSection(heading: "Searches per Month", body: "Monthly search volume showing how your search behavior changed over time."),
                HelpSection(heading: "Searches by Hour", body: "Distribution of searches across hours of the day. Reveals when you were most curious or browsing."),
                HelpSection(heading: "Top Searched Terms", body: "Your most frequently searched queries, ranked by count with visual bars."),
            ]

        // MARK: Activity Feed

        case .feedPosts:
            return [
                HelpSection(heading: nil, body: "A scrollable feed of all your Facebook posts in reverse chronological order."),
                HelpSection(heading: "Filtering", body: "Use the tabs at the top to switch between all posts, your own posts, wall posts, and group posts. The search bar filters posts by text content."),
                HelpSection(heading: "Infinite Scroll", body: "Posts load in batches as you scroll down. The total count is shown in the navigation bar."),
            ]

        case .feedComments:
            return [
                HelpSection(heading: nil, body: "Every comment you've written on Facebook, shown in reverse chronological order."),
                HelpSection(heading: "Search", body: "Use the search bar to filter comments by text content. Useful for finding a specific comment you remember writing."),
            ]

        case .feedLikes:
            return [
                HelpSection(heading: nil, body: "All reactions you've given on Facebook content \u{2014} likes, loves, hahas, and more \u{2014} in reverse chronological order."),
                HelpSection(heading: "Search", body: "Filter by the title or description of the content you reacted to."),
            ]

        case .feedSearches:
            return [
                HelpSection(heading: nil, body: "Your recent Facebook search queries in reverse chronological order. Each entry shows what you searched for and when."),
            ]

        case .feedNotifications:
            return [
                HelpSection(heading: nil, body: "Recent Facebook notifications from your data export, including likes, comments, tags, and other activity that triggered a notification."),
            ]

        case .feedVisits:
            return [
                HelpSection(heading: nil, body: "Pages, profiles, groups, and events you recently visited on Facebook."),
                HelpSection(heading: "Categories", body: "Use the tabs to filter by visit type: Events, Groups, Profiles, or Pages."),
            ]
        }
    }
}
