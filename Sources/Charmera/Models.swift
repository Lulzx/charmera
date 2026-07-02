import Foundation

/// One photo living on the camera.
struct PhotoItem: Identifiable, Hashable {
    let url: URL
    let date: Date

    var id: URL { url }
    var name: String { url.lastPathComponent }
}

/// Where the app is exporting filtered copies.
enum ExportState: Equatable {
    case idle
    case working(done: Int, total: Int)
    case finished(count: Int, folder: URL)
    case failed(String)
}
