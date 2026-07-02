import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Wordmark
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Charmera")
                        .font(Theme.title)
                        .foregroundStyle(Theme.ink)
                    Text("📸")
                        .font(.system(size: 22))
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(model.isCameraConnected ? Color.green : Theme.rose)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
            }

            Spacer()

            // Selection controls
            if !model.photos.isEmpty {
                HStack(spacing: 10) {
                    Text("\(model.selection.count) selected")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                        .contentTransition(.numericText())

                    Button(model.allSelected ? "Clear" : "Select All") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            model.allSelected ? model.clearSelection() : model.selectAll()
                        }
                    }
                    .buttonStyle(PillButtonStyle(filled: false, tint: Theme.sky))
                }
            }

            // Source switching
            if model.cameraFolders.count > 1 {
                Menu {
                    ForEach(model.cameraFolders, id: \.self) { folder in
                        Button(PhotoLibrary.label(for: folder)) { model.load(folder: folder) }
                    }
                } label: {
                    Image(systemName: "sdcard")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 34)
            }

            Button {
                model.chooseFolderManually()
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(IconButtonStyle())
            .help("Choose a folder manually")

            Button {
                withAnimation { model.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(IconButtonStyle())
            .help("Refresh camera (⌘R)")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Theme.paper)
    }

    private var statusText: String {
        if model.isCameraConnected {
            return "\(model.sourceLabel) · \(model.photos.count) photos"
        }
        return "No camera found"
    }
}
