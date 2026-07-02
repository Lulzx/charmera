import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 168, maximum: 220), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(model.photos) { photo in
                    PhotoCell(photo: photo,
                              isSelected: model.selection.contains(photo.url))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                model.toggle(photo)
                            }
                        }
                }
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
    }
}

/// A single polaroid-ish tile with its own async thumbnail + selection chrome.
struct PhotoCell: View {
    let photo: PhotoItem
    let isSelected: Bool

    @State private var image: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.cream)

                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(8)
            .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Theme.amber : Theme.hairline,
                              lineWidth: isSelected ? 3 : 1)
        )
        .overlay(alignment: .topTrailing) {
            SelectionBadge(isSelected: isSelected)
                .padding(10)
        }
        .shadow(color: Theme.ink.opacity(isSelected ? 0.18 : 0.08),
                radius: isSelected ? 10 : 5, y: 4)
        .scaleEffect(isSelected ? 1.02 : 1)
        .rotationEffect(.degrees(isSelected ? 0 : 0))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .task(id: photo.url) {
            image = await ThumbnailProvider.shared.thumbnail(for: photo.url, maxPixel: 420)
        }
    }
}

struct SelectionBadge: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Theme.amber : Color.black.opacity(0.28))
                .frame(width: 24, height: 24)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}
