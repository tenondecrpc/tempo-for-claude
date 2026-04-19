import Foundation

enum AppearanceModeSync {
    static let fileName = "appearance-mode.json"

    static func fileURL(fileManager: FileManager = .default) -> URL {
        AlertPreferencesSync
            .trackerDirectory(fileManager: fileManager)
            .appendingPathComponent(fileName, isDirectory: false)
    }

    static func write(
        _ appearanceMode: AppearanceMode,
        fileManager: FileManager = .default
    ) throws {
        let directory = AlertPreferencesSync.trackerDirectory(fileManager: fileManager)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(appearanceMode)
        try data.write(to: fileURL(fileManager: fileManager), options: .atomic)
    }
}
