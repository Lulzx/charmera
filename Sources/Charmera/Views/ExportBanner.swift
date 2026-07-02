import SwiftUI

/// A floating status pill that reports on the batch export.
struct ExportBanner: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Group {
            switch model.exportState {
            case .idle:
                EmptyView()

            case let .working(done, total):
                banner(tint: Theme.sky) {
                    HStack(spacing: 12) {
                        ProgressView().controlSize(.small)
                        Text("Developing… \(done)/\(total)")
                            .font(Theme.body)
                            .foregroundStyle(Theme.ink)
                        ProgressView(value: Double(done), total: Double(total))
                            .frame(width: 120)
                            .tint(Theme.amber)
                    }
                }

            case let .finished(count, _):
                banner(tint: Color.green) {
                    HStack(spacing: 12) {
                        Text("✨")
                        Text("Saved \(count) filtered photo\(count == 1 ? "" : "s")")
                            .font(Theme.body)
                            .foregroundStyle(Theme.ink)
                        Button("Show in Finder") { model.revealExportFolder() }
                            .buttonStyle(PillButtonStyle(filled: false, tint: Theme.sky))
                            .controlSize(.small)
                        closeButton
                    }
                }

            case let .failed(message):
                banner(tint: Theme.rose) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.rose)
                        Text(message)
                            .font(Theme.body)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                        closeButton
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.exportState)
    }

    private var closeButton: some View {
        Button {
            model.dismissExportBanner()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func banner<Content: View>(tint: Color, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Theme.ink.opacity(0.18), radius: 14, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.5), lineWidth: 1.5)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
