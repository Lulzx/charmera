// Draws the Charmera app icon (a cute cream camera on a warm gradient tile) and
// writes a 1024×1024 PNG. Run: swiftc tools/make_icon.swift -o /tmp/mkicon && /tmp/mkicon out.png
import AppKit

let S: CGFloat = 1024
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("no context")
}

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

// Palette (matches the app's Theme)
let amber   = color(0.94, 0.60, 0.24)
let amberDp = color(0.86, 0.40, 0.30)
let rose    = color(0.85, 0.44, 0.42)
let cream   = color(0.99, 0.98, 0.95)
let ink     = color(0.24, 0.20, 0.17)
let sky     = color(0.55, 0.72, 0.78)

// Rounded tile with a warm diagonal gradient
let inset: CGFloat = 84
let tile = CGRect(x: inset, y: inset, width: S - inset*2, height: S - inset*2)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 210, cornerHeight: 210, transform: nil)
ctx.saveGState()
ctx.addPath(tilePath); ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [amber, amberDp, rose] as CFArray,
                      locations: [0, 0.55, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: inset, y: S - inset),
                       end: CGPoint(x: S - inset, y: inset), options: [])
// soft top glow
ctx.setFillColor(color(1, 1, 1, 0.10))
ctx.fillEllipse(in: CGRect(x: 180, y: 560, width: 720, height: 420))
ctx.restoreGState()

// Camera body (cream) with a drop shadow
let body = CGRect(x: 262, y: 300, width: 500, height: 360)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: color(0.3, 0.15, 0.1, 0.35))
let bodyPath = CGPath(roundedRect: body, cornerWidth: 66, cornerHeight: 66, transform: nil)
ctx.addPath(bodyPath); ctx.setFillColor(cream); ctx.fillPath()
ctx.restoreGState()

// Viewfinder hump on top-left of the body
let hump = CGRect(x: 300, y: 648, width: 150, height: 56)
ctx.addPath(CGPath(roundedRect: hump, cornerWidth: 22, cornerHeight: 22, transform: nil))
ctx.setFillColor(cream); ctx.fillPath()

// Shutter button + flash on top-right
ctx.setFillColor(amber)
ctx.fillEllipse(in: CGRect(x: 690, y: 654, width: 46, height: 46))
ctx.addPath(CGPath(roundedRect: CGRect(x: 590, y: 596, width: 74, height: 40),
                   cornerWidth: 12, cornerHeight: 12, transform: nil))
ctx.setFillColor(sky); ctx.fillPath()

// Lens — concentric rings
let lc = CGPoint(x: 512, y: 470)
func ring(_ radius: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: lc.x - radius, y: lc.y - radius, width: radius*2, height: radius*2))
}
ring(146, ink)
ring(128, amber)
ring(108, ink)
ring(84, sky)
ring(60, color(0.72, 0.85, 0.88))       // inner glass
// glass highlight
ctx.setFillColor(color(1, 1, 1, 0.75))
ctx.fillEllipse(in: CGRect(x: lc.x - 40, y: lc.y + 6, width: 42, height: 30))

// Three little filter dots along the bottom of the body
let dots: [CGColor] = [rose, amber, sky]
for (i, c) in dots.enumerated() {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: 322 + CGFloat(i)*46, y: 330, width: 30, height: 30))
}

// A cheeky sparkle to signal "filters"
func sparkle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x, y: y + r))
    p.addQuadCurve(to: CGPoint(x: x + r, y: y), control: CGPoint(x: x + r*0.25, y: y + r*0.25))
    p.addQuadCurve(to: CGPoint(x: x, y: y - r), control: CGPoint(x: x + r*0.25, y: y - r*0.25))
    p.addQuadCurve(to: CGPoint(x: x - r, y: y), control: CGPoint(x: x - r*0.25, y: y - r*0.25))
    p.addQuadCurve(to: CGPoint(x: x, y: y + r), control: CGPoint(x: x - r*0.25, y: y + r*0.25))
    ctx.addPath(p); ctx.fillPath()
}
sparkle(700, 470, 40, cream)
sparkle(660, 540, 20, color(1, 1, 1, 0.85))

guard let img = ctx.makeImage() else { fatalError("no image") }
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("no dest")
}
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outPath)")
