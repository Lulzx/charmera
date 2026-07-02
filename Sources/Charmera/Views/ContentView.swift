import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider().overlay(Theme.hairline)

            if model.photos.isEmpty {
                EmptyStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GalleryView()
            }

            if !model.photos.isEmpty {
                Divider().overlay(Theme.hairline)
                FilterBar()
            }
        }
        .background(Theme.cream)
        .overlay(alignment: .bottom) {
            ExportBanner()
                .padding(.bottom, model.photos.isEmpty ? 24 : 150)
                .padding(.horizontal, 24)
        }
    }
}

/// Shown when no camera is mounted / no photos were found.
struct EmptyStateView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 18) {
            Text("📷")
                .font(.system(size: 68))
                .rotationEffect(.degrees(-8))
            Text("No camera photos yet")
                .font(Theme.title)
                .foregroundStyle(Theme.ink)
            Text("Plug in your Kodak Charmera, then hit refresh.\nI'll look for a DCIM folder on any connected card.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PillButtonStyle())

                Button {
                    model.chooseFolderManually()
                } label: {
                    Label("Choose Folder…", systemImage: "folder")
                }
                .buttonStyle(PillButtonStyle(filled: false))
            }
            .padding(.top, 6)
        }
        .padding(40)
    }
}
