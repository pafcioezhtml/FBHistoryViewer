import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var profile: ProfileData = ProfileData()
    var isLoading = false
    var loadError: String?
    private var loaded = false

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
                let repo = ProfileRepository()
                profile = try await repo.load(dbQueue: DatabaseManager.shared.dbQueue)
                loaded = true
            } catch {
                loadError = error.localizedDescription
            }
            isLoading = false
        }
    }
}
