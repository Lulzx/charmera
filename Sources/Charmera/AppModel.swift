import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    // Source
    @Published var cameraFolders: [URL] = []
    @Published var activeFolder: URL?
    @Published var photos: [PhotoItem] = []

    // Selection & filter choice
    @Published var selection: Set<URL> = []
    @Published var chosenFilter: NostalgicFilter = NostalgicFilter.all[0]
    @Published var dateStamp: Bool = true

    // Export
    @Published var exportFolder: URL = AppModel.defaultExportFolder()
    @Published var exportState: ExportState = .idle

    var isCameraConnected: Bool { activeFolder != nil }
    var sourceLabel: String {
        guard let f = activeFolder else { return "No camera found" }
        return PhotoLibrary.label(for: f)
    }

    /// The photo whose look we show in the filter previews — first selected, else first photo.
    var heroPhoto: PhotoItem? {
        if let first = photos.first(where: { selection.contains($0.url) }) { return first }
        return photos.first
    }

    // MARK: Source detection

    func refresh() {
        let folders = PhotoLibrary.detectCameraFolders()
        cameraFolders = folders
        if let active = activeFolder, folders.contains(active) {
            load(folder: active)
        } else if let first = folders.first {
            load(folder: first)
        } else {
            activeFolder = nil
            photos = []
            selection = []
        }
    }

    func load(folder: URL) {
        activeFolder = folder
        let loaded = PhotoLibrary.loadPhotos(from: folder)
        photos = loaded
        selection = selection.filter { url in loaded.contains(where: { $0.url == url }) }
    }

    /// Let the user point at a folder by hand (e.g. an already-imported set).
    func chooseFolderManually() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        panel.message = "Choose a folder of photos"
        if panel.runModal() == .OK, let url = panel.url {
            if !cameraFolders.contains(url) { cameraFolders.append(url) }
            load(folder: url)
        }
    }

    // MARK: Selection helpers

    func toggle(_ item: PhotoItem) {
        if selection.contains(item.url) { selection.remove(item.url) }
        else { selection.insert(item.url) }
    }

    func selectAll() { selection = Set(photos.map(\.url)) }
    func clearSelection() { selection.removeAll() }
    var allSelected: Bool { !photos.isEmpty && selection.count == photos.count }

    // MARK: Export

    func chooseExportFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Save Here"
        panel.directoryURL = exportFolder
        if panel.runModal() == .OK, let url = panel.url {
            exportFolder = url
        }
    }

    /// Apply the chosen filter to every selected photo and write copies out.
    func applyFilterToSelection() {
        let targets = photos.filter { selection.contains($0.url) }
        guard !targets.isEmpty else { return }
        let filter = chosenFilter
        let stamp = dateStamp
        let destination = exportFolder

        exportState = .working(done: 0, total: targets.count)

        Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            try? fm.createDirectory(at: destination, withIntermediateDirectories: true)

            var results: [Bool] = []
            var firstError: String?
            for (i, item) in targets.enumerated() {
                do {
                    _ = try FilterEngine.shared.export(url: item.url, filter: filter,
                                                       to: destination, dateStamp: stamp)
                    results.append(true)
                } catch {
                    results.append(false)
                    if firstError == nil { firstError = error.localizedDescription }
                }
                let doneSoFar = i + 1
                await MainActor.run {
                    self.exportState = .working(done: doneSoFar, total: targets.count)
                }
            }

            let written = results.filter { $0 }.count
            let finalError = firstError
            await MainActor.run {
                if let err = finalError, written == 0 {
                    self.exportState = .failed(err)
                } else {
                    self.exportState = .finished(count: written, folder: destination)
                }
            }
        }
    }

    func revealExportFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: exportFolder.path)
    }

    func dismissExportBanner() { exportState = .idle }

    static func defaultExportFolder() -> URL {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return pictures.appendingPathComponent("Charmera", isDirectory: true)
    }
}
