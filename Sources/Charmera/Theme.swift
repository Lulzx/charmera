import SwiftUI

/// A soft, warm, film-inspired palette so the whole app feels like a shoebox of
/// old prints rather than a utility.
enum Theme {
    static let cream      = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let paper      = Color(red: 0.99, green: 0.98, blue: 0.95)
    static let ink        = Color(red: 0.24, green: 0.20, blue: 0.17)
    static let inkSoft    = Color(red: 0.45, green: 0.40, blue: 0.35)
    static let amber      = Color(red: 0.90, green: 0.55, blue: 0.22)
    static let amberDeep  = Color(red: 0.82, green: 0.42, blue: 0.16)
    static let rose       = Color(red: 0.85, green: 0.44, blue: 0.42)
    static let sky        = Color(red: 0.55, green: 0.70, blue: 0.74)
    static let hairline   = Color(red: 0.85, green: 0.81, blue: 0.74)

    static let title = Font.system(size: 26, weight: .heavy, design: .rounded)
    static let heading = Font.system(size: 15, weight: .bold, design: .rounded)
    static let body = Font.system(size: 13, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 11, weight: .semibold, design: .rounded)
}

/// The chunky, tactile pill button used for the main actions.
struct PillButtonStyle: ButtonStyle {
    var filled: Bool = true
    var tint: Color = Theme.amber

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.heading)
            .foregroundStyle(filled ? Color.white : tint)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(filled ? tint : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(filled ? Color.clear : tint.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: filled ? tint.opacity(0.35) : .clear, radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Small round icon button (refresh, choose folder, etc).
struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: 34, height: 34)
            .background(Circle().fill(Color.white.opacity(0.7)))
            .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
