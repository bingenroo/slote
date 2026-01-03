# Slote - Cross-Platform Note-Taking Application

A lightweight, cross-platform note-taking application that combines drawing and typing capabilities in a unified interface.

## Repository Structure

This is a **monorepo** containing:

- **`slote_app/`** - Main Flutter application
  - Models, views, controllers
  - HiveDB services
  - Platform-specific code (Android, iOS, Web, Windows, macOS, Linux)

- **`slote_components/`** - Reusable component packages
  - `slote_viewport/` - Viewport/zoom/pan functionality
  - `slote_undo_redo/` - Undo/redo system
  - `slote_rich_text/` - Rich text editing (Word-style)
  - `slote_draw/` - Custom drawing implementation
  - `slote_theme/` - Theming system
  - `slote_shared/` - Shared utilities and resources

## Getting Started

### Prerequisites

- Flutter SDK 3.7.2+
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/bingenroo/slote.git
cd slote

# Install dependencies for the main app
cd slote_app
flutter pub get

# Install dependencies for components (if developing components)
cd ../slote_components/slote_viewport
flutter pub get
# Repeat for other components as needed
```

### Running the App

```bash
cd slote_app
flutter run
```

## Development

### Working with Components

Components are developed independently but used by the main app via path dependencies:

```yaml
# slote_app/pubspec.yaml
dependencies:
  slote_viewport:
    path: ../slote_components/slote_viewport
```

### Branches

- `main` - Main development branch
- `noobee` - Feature branch
- `the_bird` - Feature branch

## Documentation

- [Product Requirements Document (PRD)](slote_app/PRD.md)
- [Repository Restructure Plan](docs/REPOSITORY_RESTRUCTURE_PLAN.md)
- [Concurrent Development Guide](docs/CONCURRENT_DEVELOPMENT_GUIDE.md)
- [Cross-Platform Testing Plan](docs/CROSS_PLATFORM_TESTING_PLAN.md)
- [Hive Browser Plan](docs/HIVE_BROWSER_PLAN.md)

## Project Status

This project is in active development. See the [PRD](slote_app/PRD.md) for feature roadmap and priorities.

## License

[Add your license here]

---

**Note**: This repository was restructured into a monorepo format while preserving all git history. All branches and commit history from the original `slote_app` repository are maintained.

