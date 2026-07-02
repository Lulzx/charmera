import SwiftUI

struct FilterBar: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            // Filter preview chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(NostalgicFilter.all) { filter in
                        FilterChip(filter: filter,
                                   hero: model.heroPhoto,
                                   isChosen: model.chosenFilter.id == filter.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    model.chosenFilter = filter
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 92)

            // Action row
            HStack(spacing: 14) {
                Toggle(isOn: $model.dateStamp) {
                    Label("Date stamp", systemImage: "calendar")
                        .font(Theme.caption)
                }
                .toggleStyle(.switch)
                .tint(Theme.amber)
                .fixedSize()

                Button {
                    model.chooseExportFolder()
                } label: {
                    Label(model.exportFolder.lastPathComponent, systemImage: "tray.and.arrow.down")
                        .font(Theme.caption)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.inkSoft)
                .help("Filtered copies are saved here — click to change")

                Spacer()

                Text(applyLabel)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)

                Button {
                    model.applyFilterToSelection()
                } label: {
                    Label("Apply \(model.chosenFilter.emoji)", systemImage: "wand.and.stars")
                }
                .buttonStyle(PillButtonStyle())
                .disabled(model.selection.isEmpty || isWorking)
                .opacity(model.selection.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
        .padding(.top, 14)
        .background(Theme.paper)
    }

    private var isWorking: Bool {
        if case .working = model.exportState { return true }
        return false
    }

    private var applyLabel: String {
        let n = model.selection.count
        if n == 0 { return "Select photos to filter" }
        return "\(model.chosenFilter.name) → \(n) photo\(n == 1 ? "" : "s")"
    }
}

/// A tappable filter preview rendered on the current hero photo.
struct FilterChip: View {
    let filter: NostalgicFilter
    let hero: PhotoItem?
    let isChosen: Bool

    @State private var preview: NSImage?

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.cream)
                if let preview {
                    Image(nsImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Text(filter.emoji).font(.system(size: 22))
                }
            }
            .frame(width: 64, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isChosen ? Theme.amber : Theme.hairline,
                                  lineWidth: isChosen ? 3 : 1)
            )

            Text(filter.name)
                .font(.system(size: 10, weight: isChosen ? .heavy : .semibold, design: .rounded))
                .foregroundStyle(isChosen ? Theme.amberDeep : Theme.inkSoft)
                .lineLimit(1)
        }
        .scaleEffect(isChosen ? 1.06 : 1)
        .task(id: taskKey) {
            guard let hero else { preview = nil; return }
            preview = FilterEngine.shared.preview(url: hero.url, filter: filter)
        }
    }

    private var taskKey: String { "\(hero?.url.path ?? "none")#\(filter.id)" }
}
