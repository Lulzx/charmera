import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreText
import ImageIO
import UniformTypeIdentifiers

/// A recipe is a small bag of tuning knobs. Each nostalgic preset is just a
/// different set of values, which keeps the pipeline in one predictable place.
struct Recipe {
    var photoEffect: String? = nil   // an Apple CIPhotoEffect* filter, optional
    var saturation: Float = 1.0
    var contrast: Float = 1.0
    var brightness: Float = 0.0
    var warmth: Float = 0.0          // + warmer, - cooler
    var gamma: Float = 1.0
    var fadeBlacks: Float = 0.0      // lifts the shadows for that washed-out look
    var sepia: Float = 0.0
    var vignette: Float = 0.0        // intensity
    var vignetteRadius: Float = 1.5
    var grain: Float = 0.0           // 0…~0.2 subtle film grain
}

/// A named, tappable filter.
struct NostalgicFilter: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let recipe: Recipe

    static func == (l: NostalgicFilter, r: NostalgicFilter) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    static let all: [NostalgicFilter] = [
        NostalgicFilter(id: "faded", name: "Faded Film", emoji: "🎞",
            recipe: Recipe(photoEffect: "CIPhotoEffectFade", saturation: 0.85, contrast: 0.92,
                           brightness: 0.02, warmth: 0.5, gamma: 1.05, fadeBlacks: 0.06,
                           vignette: 0.6, vignetteRadius: 1.7, grain: 0.10)),
        NostalgicFilter(id: "kodachrome", name: "Kodachrome '74", emoji: "☀️",
            recipe: Recipe(photoEffect: "CIPhotoEffectTransfer", saturation: 1.15, contrast: 1.06,
                           warmth: 0.7, vignette: 0.8, vignetteRadius: 1.5, grain: 0.07)),
        NostalgicFilter(id: "sepia", name: "Sepia Sunday", emoji: "📜",
            recipe: Recipe(contrast: 0.98, warmth: 0.3, sepia: 0.75,
                           vignette: 0.9, vignetteRadius: 1.4, grain: 0.12)),
        NostalgicFilter(id: "disposable", name: "Disposable", emoji: "⚡️",
            recipe: Recipe(photoEffect: "CIPhotoEffectInstant", saturation: 1.05, contrast: 1.12,
                           warmth: -0.2, fadeBlacks: 0.03, vignette: 1.1, vignetteRadius: 1.3, grain: 0.14)),
        NostalgicFilter(id: "sunbleached", name: "Sun-bleached", emoji: "🌻",
            recipe: Recipe(saturation: 0.7, contrast: 0.9, brightness: 0.05, warmth: 0.8,
                           gamma: 1.1, fadeBlacks: 0.10, vignette: 0.4, vignetteRadius: 1.8, grain: 0.06)),
        NostalgicFilter(id: "chrome", name: "Retro Chrome", emoji: "🪩",
            recipe: Recipe(photoEffect: "CIPhotoEffectChrome", saturation: 1.1, contrast: 1.04,
                           warmth: 0.3, vignette: 0.7, vignetteRadius: 1.5, grain: 0.06)),
        NostalgicFilter(id: "noir", name: "Noir '59", emoji: "🖤",
            recipe: Recipe(photoEffect: "CIPhotoEffectNoir", contrast: 1.1,
                           vignette: 1.0, vignetteRadius: 1.4, grain: 0.13))
    ]
}

/// Runs recipes over images. One shared CIContext is reused for speed.
final class FilterEngine {
    static let shared = FilterEngine()
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let previewCache = NSCache<NSString, NSImage>()

    // MARK: Pipeline

    func apply(_ recipe: Recipe, to input: CIImage) -> CIImage {
        var img = input

        // Warmth via a predictable channel scale (R up / B down, or the reverse).
        if recipe.warmth != 0 {
            let w = CGFloat(recipe.warmth)
            img = img.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1 + 0.09 * w, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1 + 0.02 * w, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1 - 0.09 * w, w: 0)
            ])
        }

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: recipe.saturation,
            kCIInputContrastKey: recipe.contrast,
            kCIInputBrightnessKey: recipe.brightness
        ])

        if recipe.gamma != 1 {
            img = img.applyingFilter("CIGammaAdjust", parameters: ["inputPower": recipe.gamma])
        }

        if recipe.fadeBlacks > 0 {
            let f = CGFloat(recipe.fadeBlacks)
            img = img.applyingFilter("CIColorMatrix", parameters: [
                "inputBiasVector": CIVector(x: f, y: f, z: f, w: 0)
            ])
        }

        if let effect = recipe.photoEffect {
            img = img.applyingFilter(effect)
        }

        if recipe.sepia > 0 {
            img = img.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: recipe.sepia])
        }

        if recipe.vignette > 0 {
            img = img.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: recipe.vignette,
                kCIInputRadiusKey: recipe.vignetteRadius
            ])
        }

        if recipe.grain > 0 {
            img = addGrain(to: img, amount: recipe.grain)
        }

        return img.cropped(to: input.extent)
    }

    private func addGrain(to image: CIImage, amount: Float) -> CIImage {
        let noise = CIFilter.randomGenerator().outputImage!.cropped(to: image.extent)
        let mono = noise.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0, kCIInputContrastKey: 1.0, kCIInputBrightnessKey: 0.0
        ])
        let faint = mono.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(amount))
        ])
        return faint.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: image
        ])
    }

    // MARK: Live preview (runs on a tiny proxy)

    func preview(url: URL, filter: NostalgicFilter, size: CGFloat = 200) -> NSImage? {
        let key = "\(url.path)#\(filter.id)@\(Int(size))" as NSString
        if let hit = previewCache.object(forKey: key) { return hit }
        guard let cg = ThumbnailProvider.shared.cgThumbnail(for: url, maxPixel: size) else { return nil }
        let input = CIImage(cgImage: cg)
        let out = apply(filter.recipe, to: input)
        guard let rendered = context.createCGImage(out, from: out.extent) else { return nil }
        let img = NSImage(cgImage: rendered, size: NSSize(width: rendered.width, height: rendered.height))
        previewCache.setObject(img, forKey: key)
        return img
    }

    // MARK: Full-resolution export

    /// Applies the filter at full resolution and writes a JPEG into `destination`.
    func export(url: URL, filter: NostalgicFilter, to destination: URL, dateStamp: Bool) throws -> URL {
        guard let input = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            throw NSError(domain: "Charmera", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read \(url.lastPathComponent)"])
        }
        let out = apply(filter.recipe, to: input)
        guard var cg = context.createCGImage(out, from: out.extent) else {
            throw NSError(domain: "Charmera", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not render \(url.lastPathComponent)"])
        }

        if dateStamp {
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            cg = stamp(cg, date: date)
        }

        let base = url.deletingPathExtension().lastPathComponent
        let dest = uniqueURL(in: destination, base: "\(base)-\(filter.id)", ext: "jpg")

        guard let imageDest = CGImageDestinationCreateWithURL(dest as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw NSError(domain: "Charmera", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create output file"])
        }
        let props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.92]
        CGImageDestinationAddImage(imageDest, cg, props as CFDictionary)
        guard CGImageDestinationFinalize(imageDest) else {
            throw NSError(domain: "Charmera", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Could not write \(dest.lastPathComponent)"])
        }
        return dest
    }

    /// Burns a warm, glowing date into the bottom-right corner — the classic
    /// point-and-shoot look.
    private func stamp(_ cg: CGImage, date: Date) -> CGImage {
        let w = cg.width, h = cg.height
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return cg }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        let fmt = DateFormatter()
        fmt.dateFormat = "MM' 'dd' 'yyyy"
        let text = fmt.string(from: date)

        let fontSize = CGFloat(h) / 24
        let font = CTFontCreateWithName("Menlo-Bold" as CFString, fontSize, nil)
        let color = CGColor(red: 1.0, green: 0.58, blue: 0.15, alpha: 0.95)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: fontSize * 0.08
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
        let bounds = CTLineGetImageBounds(line, ctx)
        let margin = fontSize
        ctx.textPosition = CGPoint(x: CGFloat(w) - bounds.width - margin, y: margin)
        ctx.setShadow(offset: .zero, blur: fontSize * 0.6,
                      color: CGColor(red: 1, green: 0.35, blue: 0, alpha: 0.9))
        CTLineDraw(line, ctx)

        return ctx.makeImage() ?? cg
    }

    private func uniqueURL(in dir: URL, base: String, ext: String) -> URL {
        let fm = FileManager.default
        var candidate = dir.appendingPathComponent("\(base).\(ext)")
        var n = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base)-\(n).\(ext)")
            n += 1
        }
        return candidate
    }
}
