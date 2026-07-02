import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Finds the camera, lists its photos and produces thumbnails.
enum PhotoLibrary {

    /// Look through every mounted volume for one that looks like a camera card
    /// (i.e. it has a `DCIM` folder). The Kodak Charmera mounts exactly like this.
    static func detectCameraFolders() -> [URL] {
        let fm = FileManager.default
        guard let volumes = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                                  options: [.skipHiddenVolumes]) else { return [] }
        var found: [URL] = []
        for vol in volumes {
            let dcim = vol.appendingPathComponent("DCIM", isDirectory: true)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: dcim.path, isDirectory: &isDir), isDir.boolValue {
                found.append(dcim)
            }
        }
        return found
    }

    /// A friendly label for a camera folder, e.g. "NO NAME" or the volume name.
    static func label(for folder: URL) -> String {
        // folder is .../<Volume>/DCIM
        let volume = folder.deletingLastPathComponent()
        let name = (try? volume.resourceValues(forKeys: [.volumeNameKey]).volumeName) ?? nil
        return name ?? volume.lastPathComponent
    }

    /// All JPEG stills in a folder (recursively), newest first, ignoring AppleDouble
    /// sidecar files (the `._PICT…` ones) and video clips.
    static func loadPhotos(from folder: URL) -> [PhotoItem] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.contentModificationDateKey, .isRegularFileKey]
        guard let en = fm.enumerator(at: folder,
                                     includingPropertiesForKeys: keys,
                                     options: [.skipsHiddenFiles]) else { return [] }
        var items: [PhotoItem] = []
        for case let url as URL in en {
            guard url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg"
            else { continue }
            if url.lastPathComponent.hasPrefix("._") { continue }
            let vals = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            let date = vals?.contentModificationDate ?? .distantPast
            items.append(PhotoItem(url: url, date: date))
        }
        return items.sorted { $0.date > $1.date }
    }
}

/// Loads & caches downscaled thumbnails off the main thread using ImageIO,
/// which is far faster than decoding full frames for a grid.
final class ThumbnailProvider {
    static let shared = ThumbnailProvider()
    private let cache = NSCache<NSString, NSImage>()
    private let queue = DispatchQueue(label: "charmera.thumbs", qos: .userInitiated, attributes: .concurrent)

    func thumbnail(for url: URL, maxPixel: CGFloat) async -> NSImage? {
        let key = "\(url.path)@\(Int(maxPixel))" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        return await withCheckedContinuation { cont in
            queue.async {
                let img = Self.make(url: url, maxPixel: maxPixel)
                if let img { self.cache.setObject(img, forKey: key) }
                cont.resume(returning: img)
            }
        }
    }

    /// A CGImage thumbnail — handy when we need to run Core Image filters on a
    /// small proxy for the live filter previews.
    func cgThumbnail(for url: URL, maxPixel: CGFloat) -> CGImage? {
        Self.makeCG(url: url, maxPixel: maxPixel)
    }

    private static func makeCG(url: URL, maxPixel: CGFloat) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    private static func make(url: URL, maxPixel: CGFloat) -> NSImage? {
        guard let cg = makeCG(url: url, maxPixel: maxPixel) else { return nil }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}
