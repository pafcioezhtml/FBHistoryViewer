import Foundation
import Observation

@Observable
final class AppState {
    var hasImportedData: Bool = false
    var importPipeline: ImportPipeline?
    var showingImport: Bool = false
    var importError: String?

    init() {
        checkExistingData()
    }

    private func checkExistingData() {
        do {
            let count = try DatabaseManager.shared.dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM import_state") ?? 0
            }
            hasImportedData = count > 0
        } catch {
            hasImportedData = false
        }
    }

    func startImport(from url: URL) {
        let pipeline = ImportPipeline()
        importPipeline = pipeline
        showingImport = true
        pipeline.start(exportRoot: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.showingImport = false
                switch result {
                case .success:
                    self?.hasImportedData = true
                    self?.importPipeline = nil
                case .failure(let error):
                    self?.importError = error.localizedDescription
                    self?.importPipeline = nil
                }
            }
        }
    }
}
