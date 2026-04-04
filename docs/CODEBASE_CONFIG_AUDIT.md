# Codebase directory and config audit (Slote)

This document lists every directory that contains configuration tied to the repo/package name **Slote** / **slote**, and what each file contains. Use it when renaming the repo or packages.

## Root

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: slote`, `description: "Slote - Cross-Platform Note-Taking Application"`, dependency keys `viewport`, `rich_text`, `draw`, `theme`, `shared` (among others) |
| `analysis_options.yaml` | No package name (generic linter config) |
| `devtools_options.yaml` | No package name |

## Main app – platform config

| File | Contents |
|------|----------|
| `android/app/build.gradle.kts` | `namespace = "com.example.slote"`, `applicationId = "com.example.slote"` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName`: Slote, `CFBundleIdentifier`: Slote |
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = slote`, `PRODUCT_BUNDLE_IDENTIFIER = com.example.slote` |
| `web/manifest.json` | `"name": "slote"`, `"short_name": "slote"` |

## components/viewport

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: viewport`, `description: Viewport/zoom/pan functionality for Slote` |

### components/viewport/example

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: viewport_example`, `description: Example app for viewport component`, dependency `viewport: path: ../` |
| `android/app/build.gradle.kts` | `namespace = "com.example.viewport_example"`, `applicationId = "com.example.viewport_example"` |
| `ios/Runner/Info.plist` | Display name, bundle `viewport_example` |
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = viewport_example`, `PRODUCT_BUNDLE_IDENTIFIER = com.example.viewportExample` |
| `web/manifest.json` | `"name": "viewport_example"`, `"short_name": "viewport_example"` |

## components/draw

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: draw`, `description: Custom drawing implementation for Slote` |
| (platform config at package root: android, ios, macos, web use `draw` / `com.example.draw`) |

### components/draw/example

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: draw_example`, `description: Example app for draw component`, dependency `draw: path: ../` |

## components/rich_text

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: rich_text`, `description: Rich text editing (Word-style) for Slote` |
| (platform config at package root uses `rich_text` / `com.example.rich_text`) |

### components/rich_text/example

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: rich_text_example`, `description: Example app for rich_text component`, dependency `rich_text: path: ../` |

## components/theme

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: theme`, `description: Theming system for Slote` |

(No android/ios/web/macos – library-only package.)

## components/shared

| File | Contents |
|------|----------|
| `pubspec.yaml` | `name: shared`, `description: Shared utilities and resources for Slote` |

(No android/ios/web/macos – library-only package.)

---

## Summary

- **YAML:** 9 `pubspec.yaml` files under root + `components/` (excluding vendored `appflowy_editor`), 5 `analysis_options.yaml` files, 1 `devtools_options.yaml`. Only pubspecs contain the package/repo name.
- **Android:** 4 Flutter app targets with `android/` (root app, viewport/example, draw, rich_text).
- **iOS / macOS / Web:** same four app targets plus their `example/` variants where present (see tree above).

All of these use the **slote** / **Slote** naming for the root app; component packages use **viewport**, **draw**, **rich_text**, **theme**, **shared**; example apps use **viewport_example**, etc. To rename the repo or packages, update the values in the files listed above and then update all Dart `import 'package:...'` and any Kotlin/Swift package paths that reference `com.example.*`.
