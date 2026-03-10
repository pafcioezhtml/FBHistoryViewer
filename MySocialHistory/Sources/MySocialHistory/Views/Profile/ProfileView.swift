import SwiftUI

// MARK: - Local image loader helper

struct LocalImageView: View {
    let url: URL
    let size: CGFloat

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: url) {
            image = await loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) async -> NSImage? {
        await Task.detached(priority: .userInitiated) {
            NSImage(contentsOf: url)
        }.value
    }
}

// MARK: - Info row helper

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    var viewModel: ProfileViewModel

    private let photoGridColumns = [
        GridItem(.adaptive(minimum: 120), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading profile…")
                    .padding(40)
            } else if let error = viewModel.loadError {
                ContentUnavailableView(
                    "Failed to Load Profile",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .padding(40)
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statsBar
                    aboutSection
                    if !viewModel.profile.workExperiences.isEmpty {
                        workSection
                    }
                    if !viewModel.profile.educationExperiences.isEmpty {
                        educationSection
                    }
                    if !viewModel.profile.websites.isEmpty || !viewModel.profile.screenNames.isEmpty {
                        linksSection
                    }
                    if !viewModel.profile.familyMembers.isEmpty {
                        familySection
                    }
                    if !viewModel.profile.profilePhotos.isEmpty {
                        photoHistorySection
                    }
                }
                .padding()
            }
        }
        .onAppear { viewModel.loadIfNeeded() }
        .navigationTitle("Profile")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Profile photo circle
            if let latestPhoto = viewModel.profile.profilePhotos.first {
                LocalImageView(url: latestPhoto.imageURL, size: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                if !viewModel.profile.name.isEmpty {
                    Text(viewModel.profile.name)
                        .font(.largeTitle)
                        .bold()
                }
                if !viewModel.profile.username.isEmpty {
                    Text("@\(viewModel.profile.username)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if !viewModel.profile.aboutMe.isEmpty {
                    Text(viewModel.profile.aboutMe)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack(spacing: 32) {
            statItem(count: viewModel.profile.friendsCount, label: "Friends")
            statItem(count: viewModel.profile.followersCount, label: "Followers")
        }
        .padding(.vertical, 8)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        GroupBox("About") {
            VStack(alignment: .leading, spacing: 10) {
                if !viewModel.profile.birthday.isEmpty {
                    InfoRow(icon: "birthday.cake", label: "Birthday", value: viewModel.profile.birthday)
                }
                if !viewModel.profile.city.isEmpty {
                    InfoRow(icon: "mappin.circle", label: "City", value: viewModel.profile.city)
                }
                if !viewModel.profile.hometown.isEmpty {
                    InfoRow(icon: "house", label: "Hometown", value: viewModel.profile.hometown)
                }
                if !viewModel.profile.gender.isEmpty {
                    InfoRow(icon: "person", label: "Gender", value: viewModel.profile.gender)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Work section

    private var workSection: some View {
        GroupBox("Work") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.profile.workExperiences) { work in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(work.employer)
                            .font(.headline)
                        if let title = work.title {
                            Text(title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let location = work.location {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let period = work.period {
                            Label(period, systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if work.id != viewModel.profile.workExperiences.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Education section

    private var educationSection: some View {
        GroupBox("Education") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.profile.educationExperiences) { edu in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(edu.school)
                            .font(.headline)
                        if let degree = edu.degree, let field = edu.field {
                            Text("\(degree) · \(field)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let degree = edu.degree {
                            Text(degree)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let field = edu.field {
                            Text(field)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let schoolType = edu.schoolType {
                            Text(schoolType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if edu.id != viewModel.profile.educationExperiences.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Links section

    private var linksSection: some View {
        GroupBox("Links & Social") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.profile.websites, id: \.self) { website in
                    Label(website, systemImage: "link")
                        .font(.body)
                }
                ForEach(viewModel.profile.screenNames, id: \.service) { sn in
                    Label("\(sn.name) (\(sn.service))", systemImage: "at")
                        .font(.body)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Family section

    private var familySection: some View {
        GroupBox("Family") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.profile.familyMembers, id: \.name) { member in
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(member.name)
                            .font(.body)
                        Spacer()
                        Text(member.relation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Profile Photo History

    private var photoHistorySection: some View {
        GroupBox("Profile Photo History") {
            LazyVGrid(columns: photoGridColumns, spacing: 12) {
                ForEach(viewModel.profile.profilePhotos) { photo in
                    VStack(spacing: 4) {
                        LocalImageView(url: photo.imageURL, size: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(photo.date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
