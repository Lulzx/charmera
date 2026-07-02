# Charmera 📸

A cute little macOS app (SwiftUI) that reads photos off a connected **Kodak
Charmera** (or any camera card with a `DCIM` folder), shows them in a gallery,
lets you multi-select, and applies nostalgic film filters to the whole batch in
one go.

## Features

- **Auto-detects the camera** — scans every mounted volume for a `DCIM` folder,
  so plugging in the Charmera just works. Also lets you pick a folder by hand.
- **Fast gallery** — polaroid-style tiles with ImageIO thumbnails, tap to
  multi-select, Select All / Clear.
- **7 nostalgic filters** with live previews rendered on your photo:
  Faded Film 🎞 · Kodachrome '74 ☀️ · Sepia Sunday 📜 · Disposable ⚡️ ·
  Sun-bleached 🌻 · Retro Chrome 🪩 · Noir '59 🖤
- **Batch apply + export** — filters run at full resolution via Core Image and
  save copies (originals on the card are never touched). Default output:
  `~/Pictures/Charmera`.
- **Optional retro date stamp** — the classic glowing-orange corner date.

## Building & running

This app uses SwiftUI, whose `@State`/`@Binding` are **macros** in the current
SDK. Their compiler plugin ships only with **full Xcode**, so the Command Line
Tools alone can't build it.

1. Install **Xcode** from the App Store.
2. Point the toolchain at it (one time):
   ```sh
   sudo xcode-select -s /Applications/Xcode.app
   ```
3. Build and launch:
   ```sh
   ./build.sh
   open Charmera.app
   ```

`build.sh` compiles the sources with `swiftc` and wraps the binary in a proper
`Charmera.app` bundle (Dock icon, menu bar, and the removable-volume access
prompt). If macOS asks to access files on a removable volume, click **Allow** so
the app can read the camera card.

## Project layout

```
Sources/Charmera/
  CharmeraApp.swift      # @main app + window
  Theme.swift            # warm film palette + button styles
  Models.swift           # PhotoItem, ExportState
  PhotoLibrary.swift     # camera detection + thumbnail loading (ImageIO)
  Filters.swift          # Core Image recipes, previews, full-res export, date stamp
  AppModel.swift         # app state, selection, batch export orchestration
  Views/
    ContentView.swift    # layout + empty state
    HeaderView.swift     # wordmark, status, selection controls
    GalleryView.swift    # grid + photo cells
    FilterBar.swift      # filter preview chips + apply row
    ExportBanner.swift   # floating progress / done banner
```

`Package.swift` is included for building in Xcode via SwiftPM if you prefer.
