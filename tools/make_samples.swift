// Generates colorful 1440×1080 sample JPEGs so the gallery/filters can be
// demoed without the camera. Not part of the app — just a dev/screenshot aid.
// Run: swiftc tools/make_samples.swift -o /tmp/mksamples && /tmp/mksamples <outdir>
import AppKit

let W = 1440, H = 1080
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let cs = CGColorSpaceCreateDeviceRGB()

func C(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }

// Each scene: two sky colors (top→horizon), a ground color, and a "sun" position.
struct Scene { let name: String; let sky: [CGColor]; let ground: CGColor; let sun: CGPoint?; let sunColor: CGColor }
let scenes: [Scene] = [
    Scene(name: "sunset", sky: [C(0.98,0.75,0.35), C(0.92,0.42,0.38)], ground: C(0.30,0.22,0.32), sun: CGPoint(x: 0.7, y: 0.62), sunColor: C(1,0.93,0.7)),
    Scene(name: "ocean",  sky: [C(0.55,0.78,0.88), C(0.86,0.90,0.80)], ground: C(0.16,0.42,0.55), sun: CGPoint(x: 0.3, y: 0.7), sunColor: C(1,1,0.9)),
    Scene(name: "meadow", sky: [C(0.60,0.80,0.95), C(0.88,0.94,0.98)], ground: C(0.42,0.58,0.28), sun: CGPoint(x: 0.82, y: 0.8), sunColor: C(1,0.98,0.82)),
    Scene(name: "dusk",   sky: [C(0.30,0.28,0.52), C(0.86,0.52,0.42)], ground: C(0.18,0.16,0.24), sun: CGPoint(x: 0.5, y: 0.5), sunColor: C(1,0.8,0.6)),
    Scene(name: "desert", sky: [C(0.86,0.72,0.55), C(0.95,0.86,0.68)], ground: C(0.78,0.55,0.34), sun: CGPoint(x: 0.75, y: 0.72), sunColor: C(1,0.95,0.8)),
    Scene(name: "pine",   sky: [C(0.72,0.84,0.86), C(0.90,0.92,0.86)], ground: C(0.22,0.34,0.28), sun: nil, sunColor: C(1,1,1)),
    Scene(name: "berry",  sky: [C(0.85,0.55,0.68), C(0.96,0.80,0.75)], ground: C(0.44,0.20,0.34), sun: CGPoint(x: 0.25, y: 0.6), sunColor: C(1,0.9,0.85)),
    Scene(name: "mint",   sky: [C(0.62,0.86,0.78), C(0.90,0.96,0.90)], ground: C(0.24,0.52,0.46), sun: CGPoint(x: 0.7, y: 0.75), sunColor: C(1,1,0.92)),
    Scene(name: "night",  sky: [C(0.10,0.12,0.28), C(0.32,0.24,0.42)], ground: C(0.08,0.08,0.16), sun: CGPoint(x: 0.8, y: 0.82), sunColor: C(0.95,0.95,0.85))
]

func render(_ s: Scene, index: Int) {
    guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8,
                              bytesPerRow: 0, space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
    let horizon = CGFloat(H) * 0.42
    // Sky gradient
    let grad = CGGradient(colorsSpace: cs, colors: s.sky as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: horizon, width: CGFloat(W), height: CGFloat(H) - horizon))
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: CGFloat(H)), end: CGPoint(x: 0, y: horizon), options: [])
    ctx.restoreGState()
    // Sun glow
    if let sun = s.sun {
        let p = CGPoint(x: CGFloat(W) * sun.x, y: CGFloat(H) * sun.y)
        let sunGrad = CGGradient(colorsSpace: cs,
                                 colors: [s.sunColor, CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
                                 locations: [0, 1])!
        ctx.drawRadialGradient(sunGrad, startCenter: p, startRadius: 0, endCenter: p, endRadius: 320, options: [])
    }
    // Ground with a couple of rolling hills
    ctx.setFillColor(s.ground)
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(W), height: horizon))
    ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.12))
    ctx.fillEllipse(in: CGRect(x: -200, y: horizon - 260, width: 1200, height: 360))
    ctx.fillEllipse(in: CGRect(x: 700, y: horizon - 300, width: 1300, height: 400))

    guard let img = ctx.makeImage() else { return }
    let name = String(format: "PICT%04d.jpg", index)
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.jpeg" as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    CGImageDestinationFinalize(dest)
}

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
for (i, s) in scenes.enumerated() { render(s, index: i) }
print("wrote \(scenes.count) samples to \(outDir)")
