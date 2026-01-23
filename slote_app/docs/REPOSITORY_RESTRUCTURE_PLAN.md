---
name: Repository Restructure Plan
overview: "Restructure 3 separate git repos into 2 repos: slote_app (main app with models, views, controllers, HiveDB) and slote_components (reusable sub-components: viewport, undo_redo, rich_text, draw). Remove scribble/flutter_drawing_board dependencies. Preserve all git history and branches."
todos:
  - id: create_components_repo
    content: Create slote_components repository and initialize git
    status: pending
  - id: create_package_structure
    content: Create directory structure for slote_viewport, slote_undo_redo, slote_rich_text, slote_draw, slote_theme packages
    status: pending
    dependencies:
      - create_components_repo
  - id: extract_viewport
    content: Extract viewport/zoompan components to slote_viewport package
    status: pending
    dependencies:
      - create_package_structure
  - id: extract_undo_redo
    content: Extract undo/redo functionality to slote_undo_redo package
    status: pending
    dependencies:
      - create_package_structure
  - id: extract_theme
    content: Extract theme system (provider, config) to slote_theme package
    status: pending
    dependencies:
      - create_package_structure
  - id: create_rich_text_package
    content: Create slote_rich_text package structure for rich text editing features
    status: pending
    dependencies:
      - create_package_structure
  - id: create_draw_package
    content: Create slote_draw package structure for custom drawing implementation (replacing scribble)
    status: pending
    dependencies:
      - create_package_structure
  - id: remove_scribble_deps
    content: Remove scribble and flutter_drawing_board dependencies from slote_app
    status: pending
    dependencies:
      - create_draw_package
  - id: update_slote_app_deps
    content: Update slote_app pubspec.yaml to reference all component packages
    status: pending
    dependencies:
      - extract_viewport
      - extract_undo_redo
      - extract_theme
      - create_rich_text_package
      - create_draw_package
  - id: update_slote_app_imports
    content: Update all imports in slote_app to use component packages and remove scribble imports
    status: pending
    dependencies:
      - update_slote_app_deps
  - id: migrate_models_views_controllers
    content: Ensure models, views, controllers, and HiveDB remain in slote_app (verify structure)
    status: pending
    dependencies:
      - update_slote_app_imports
  - id: cleanup_slote_app
    content: Remove extracted files from slote_app, remove scribble code, and verify app builds
    status: pending
    dependencies:
      - migrate_models_views_controllers
  - id: verify_git_history
    content: Verify all git branches are preserved and accessible
    status: pending
    dependencies:
      - cleanup_slote_app
---

# Repository Restructure Plan

## Overview

Restructure the current 3-repo setup into 2 repos with a component-based architecture:

- **slote_app**: Main application with models, views, controllers, and HiveDB
- **slote_components**: Reusable sub-components (viewport, undo_redo, rich_text, draw, theme)

**Key Changes:**

- Models, views, controllers, and HiveDB **stay in slote_app**
- Break down into focused sub-components instead of monolithic packages
- Remove `scribble` and `flutter_drawing_board` dependencies (will be replaced with custom `slote_draw`)
- Better organization aligned with PRD features

## Current State

**Repositories:**

- `/Users/bingenro/Documents/Slote/slote_app` (branches: main, noobee, the_bird)
- `/Users/bingenro/Documents/Slote/scribble` (branches: main) - **Will be removed**
- `/Users/bingenro/Documents/Slote/flutter_drawing_board` (branches: master) - **Will be removed**

**Current slote_app structure:**

**To extract to components:**

- **Viewport/ZoomPan:**
  - `lib/src/views/widgets/viewport/`
  - `lib/src/views/widgets/zoom_pan_old/`
- **Undo/Redo:**
  - `lib/src/functions/undo_redo.dart`
- **Theme system:**
  - `lib/src/providers/theme_provider.dart`
  - `lib/src/res/theme_config.dart`
- **Shared resources:**
  - `lib/src/res/string.dart`
  - `lib/src/res/assets.dart`
  - `lib/src/views/widgets/app_checkmark.dart`
  - `lib/src/views/widgets/empty_view.dart`

**To keep in slote_app:**

- `lib/main.dart` - App entry point
- `lib/src/app.dart` - App widget
- `lib/src/views/home.dart` - Home view
- `lib/src/views/create_note*.dart` - Note creation views (will use components)
- `lib/src/model/note.dart` - Note model
- `lib/src/model/note.g.dart` - Generated Hive adapter
- `lib/src/services/local_db.dart` - HiveDB service
- `lib/src/services/hive_to_sqlite_migration.dart` - Database migrations (Hive to SQLite)
- `lib/src/views/widgets/notes_*.dart` - Note-specific widgets (grid, list, items)
- Controllers (to be created/identified)

**To remove:**

- All `scribble` package usage
- All `flutter_drawing_board` package usage
- Drawing code that depends on scribble (will be replaced with custom implementation)

## Target Structure

```
slote_components/
├── slote_viewport/              # Viewport/zoom/pan functionality
│   ├── lib/
│   │   ├── slote_viewport.dart
│   │   └── src/
│   │       ├── viewport/
│   │       │   ├── viewport_surface.dart
│   │       │   └── scroll_controller.dart
│   │       └── zoom_pan/
│   │           ├── zoom_pan_surface.dart
│   │           ├── gesture_handler.dart
│   │           ├── boundary_manager.dart
│   │           ├── content_measurer.dart
│   │           └── transform_aware_scrollbar.dart
│   └── pubspec.yaml
├── slote_undo_redo/             # Undo/redo system
│   ├── lib/
│   │   ├── slote_undo_redo.dart
│   │   └── src/
│   │       ├── undo_redo_controller.dart
│   │       └── undo_redo_state.dart
│   └── pubspec.yaml
├── slote_rich_text/             # Rich text editing (Word-style)
│   ├── lib/
│   │   ├── slote_rich_text.dart
│   │   └── src/
│   │       ├── rich_text_editor.dart
│   │       ├── format_toolbar.dart
│   │       ├── text_formatter.dart
│   │       └── formatting/
│   │           ├── bold.dart
│   │           ├── italic.dart
│   │           ├── underline.dart
│   │           └── ...
│   └── pubspec.yaml
├── slote_draw/                   # Custom drawing implementation
│   ├── lib/
│   │   ├── slote_draw.dart
│   │   └── src/
│   │       ├── draw_controller.dart
│   │       ├── draw_canvas.dart
│   │       ├── tools/
│   │       │   ├── pen_tool.dart
│   │       │   ├── eraser_tool.dart
│   │       │   ├── highlighter_tool.dart
│   │       │   └── shape_tool.dart
│   │       ├── stroke/
│   │       │   ├── stroke.dart
│   │       │   └── stroke_renderer.dart
│   │       └── stylus/
│   │           ├── stylus_detector.dart
│   │           └── pressure_handler.dart
│   └── pubspec.yaml
├── slote_theme/                  # Theming system
│   ├── lib/
│   │   ├── slote_theme.dart
│   │   └── src/
│   │       ├── providers/
│   │       │   └── theme_provider.dart
│   │       └── theme_config.dart
│   └── pubspec.yaml
└── slote_shared/                 # Shared utilities and resources
    ├── lib/
    │   ├── slote_shared.dart
    │   └── src/
    │       ├── res/
    │       │   ├── strings.dart
    │       │   └── assets.dart
    │       └── widgets/
    │           ├── app_checkmark.dart
    │           └── empty_view.dart
    └── pubspec.yaml

slote_app/
├── lib/
│   ├── main.dart                 # Entry point
│   └── src/
│       ├── app.dart              # App widget
│       ├── model/
│       │   ├── note.dart         # Note model (Hive)
│       │   └── note.g.dart       # Generated
│       ├── controllers/          # App-specific controllers
│       │   └── (to be created)
│       ├── views/
│       │   ├── home.dart         # Home view
│       │   ├── create_note.dart  # Note creation (uses components)
│       │   └── widgets/
│       │       ├── notes_grid.dart
│       │       ├── notes_list.dart
│       │       ├── note_grid_item.dart
│       │       └── note_list_item.dart
│       └── services/
│           ├── local_db.dart     # HiveDB service
│           └── hive_to_sqlite_migration.dart
└── pubspec.yaml                  # Dependencies on component packages
```

## Architecture Rationale

### Why This Structure?

1. **Models, Views, Controllers in slote_app**: These are app-specific and tied to business logic. Keeping them in the main app maintains cohesion and makes the app easier to understand.

2. **Component Breakdown**: Instead of monolithic packages, we break into focused sub-components:

   - **slote_viewport**: Reusable zoom/pan functionality
   - **slote_undo_redo**: Generic undo/redo system (works with any editable content)
   - **slote_rich_text**: Rich text editing (can be used independently)
   - **slote_draw**: Custom drawing (replaces scribble, tailored to app needs)
   - **slote_theme**: Theming system (reusable across features)

3. **Custom Draw Implementation**: Replacing `scribble` and `flutter_drawing_board` with `slote_draw` allows:

   - Full control over drawing behavior
   - Better integration with text editing
   - Custom features (stylus mapping, pressure sensitivity)
   - Optimized for app's specific needs

4. **Separation of Concerns**: Each component has a single responsibility, making them:

   - Easier to test
   - Easier to maintain
   - Reusable in other projects
   - Independent versioning

## Implementation Steps

### Phase 1: Create slote_components Repository

1. **Initialize slote_components repo**

   - Create new directory `/Users/bingenro/Documents/Slote/slote_components`
   - Initialize git repository
   - Create initial commit with README

2. **Note on scribble/flutter_drawing_board**

   - These repos will NOT be migrated (they're being replaced)
   - Code can be referenced for inspiration but not directly used
   - Remove all dependencies from slote_app

### Phase 2: Create Component Packages

3. **Create package structure**

   - Create directories for each component package
   - Set up `pubspec.yaml` for each package
   - Create basic package exports (`slote_*.dart`)

4. **Extract Viewport package (slote_viewport)**

   - Move `lib/src/views/widgets/viewport/` → `slote_viewport/lib/src/viewport/`
   - Move `lib/src/views/widgets/zoom_pan_old/` → `slote_viewport/lib/src/zoom_pan/`
   - Update imports and package declarations
   - Make viewport generic (not note-specific)

5. **Extract Undo/Redo package (slote_undo_redo)**

   - Move `lib/src/functions/undo_redo.dart` → `slote_undo_redo/lib/src/`
   - Refactor to be generic (works with any editable content)
   - Support both text and drawing undo/redo
   - Update package structure

6. **Extract Theme package (slote_theme)**

   - Move `lib/src/providers/theme_provider.dart` → `slote_theme/lib/src/providers/`
   - Move `lib/src/res/theme_config.dart` → `slote_theme/lib/src/`
   - Update imports
   - Make theme system extensible for advanced theming (per PRD)

7. **Create Rich Text package (slote_rich_text)**

   - Create new package structure
   - Plan rich text editor architecture (Word-style formatting)
   - Create format toolbar component
   - Implement basic formatting (bold, italic, underline)
   - Design for extensibility (headings, lists, colors, etc.)

8. **Create Draw package (slote_draw)**

   - Create new package structure
   - Design drawing architecture (replacing scribble)
   - Implement basic drawing tools:
     - Pen tool
     - Eraser tool
     - Highlighter tool
   - Implement stroke rendering
   - Add stylus support (pressure, palm rejection)
   - Design for future features (shapes, straight lines, etc.)

9. **Create Shared package (slote_shared)**

   - Move `lib/src/res/string.dart` → `slote_shared/lib/src/res/strings.dart`
   - Move `lib/src/res/assets.dart` → `slote_shared/lib/src/res/assets.dart`
   - Move `lib/src/views/widgets/app_checkmark.dart` → `slote_shared/lib/src/widgets/`
   - Move `lib/src/views/widgets/empty_view.dart` → `slote_shared/lib/src/widgets/`

### Phase 3: Update slote_app

10. **Remove scribble dependencies**

    - Remove `scribble` from `pubspec.yaml`
    - Remove `flutter_drawing_board` from `pubspec.yaml` (if present)
    - Remove all `import 'package:scribble/...'` statements
    - Remove scribble-related code from `create_note.dart`

11. **Update slote_app dependencies**

    - Modify `pubspec.yaml` to reference component packages as path dependencies:
      ```yaml
      dependencies:
        slote_viewport:
          path: ../slote_components/slote_viewport
        slote_undo_redo:
          path: ../slote_components/slote_undo_redo
        slote_rich_text:
          path: ../slote_components/slote_rich_text
        slote_draw:
          path: ../slote_components/slote_draw
        slote_theme:
          path: ../slote_components/slote_theme
        slote_shared:
          path: ../slote_components/slote_shared
      ```


12. **Update imports in slote_app**

    - Update all imports to use component packages
    - Refactor `create_note.dart` to use `slote_draw` instead of scribble
    - Integrate `slote_rich_text` for text editing
    - Use `slote_viewport` for zoom/pan
    - Use `slote_undo_redo` for undo/redo
    - Use `slote_theme` for theming

13. **Verify structure**

    - Ensure models, views, controllers, and HiveDB remain in slote_app
    - Verify no business logic leaked into components
    - Check that components are truly reusable

14. **Clean up slote_app**

    - Remove extracted files
    - Remove scribble-related code
    - Update `lib/main.dart` to initialize components properly
    - Ensure app builds and runs

### Phase 4: Preserve Git History

15. **Preserve branches in slote_app**

    - All existing branches (main, noobee, the_bird) will remain
    - History preserved through git's natural tracking
    - Extraction commits will be added to existing branches

16. **Create branches in slote_components**

    - For each branch in slote_app, create corresponding extraction commits
    - Use git filter-repo or manual commits to extract component history
    - Maintain component versioning

17. **Final verification**

    - Verify all branches exist and are accessible
    - Test that app builds with new structure
    - Verify git history is intact
    - Test drawing functionality (custom implementation)
    - Test rich text editing
    - Test undo/redo
    - Test viewport zoom/pan

## Component Dependencies

### slote_app dependencies:

- `slote_viewport` - For zoom/pan functionality
- `slote_undo_redo` - For undo/redo system
- `slote_rich_text` - For rich text editing
- `slote_draw` - For drawing functionality
- `slote_theme` - For theming
- `slote_shared` - For shared resources

### Component internal dependencies:

- `slote_draw` may depend on `slote_viewport` (for coordinate transformations)
- `slote_rich_text` may depend on `slote_undo_redo` (for text undo/redo)
- `slote_draw` may depend on `slote_undo_redo` (for drawing undo/redo)
- All components may depend on `slote_shared` (for resources)

## Migration Strategy for Drawing

### Replacing Scribble with slote_draw

**Current scribble usage:**

- `ScribbleNotifier` for drawing state
- `ScribbleSketch` for drawing data
- JSON serialization for saving drawings

**New slote_draw approach:**

- Custom `DrawController` for drawing state
- Custom `Stroke` model for drawing data
- Efficient binary or JSON serialization
- Better integration with text editing
- Stylus support built-in

**Migration steps:**

1. Create `slote_draw` package structure
2. Implement basic drawing (pen, eraser)
3. Implement stroke rendering
4. Add serialization (compatible with existing note format initially)
5. Replace scribble in `create_note.dart`
6. Test drawing functionality
7. Add advanced features (stylus, shapes, etc.)

## Git History Preservation Strategy

**Option A: Git Subtree (Simpler)**

- Use `git subtree` to extract component files into slote_components
- Preserves history but creates merge commits
- Easier to implement

**Option B: Git Filter-Repo (More Complex)**

- Use `git filter-repo` to rewrite paths and extract component history
- Cleaner history but more complex
- Better for long-term maintenance

**Recommendation:** Start with Option A (git subtree) for simplicity, can refine later.

## Notes

- All git branches will be preserved in their respective repos
- Component packages should be properly versioned (semantic versioning)
- Consider using a monorepo tool (like `melos`) for managing multiple packages later
- Test thoroughly after each extraction phase
- Custom draw implementation is a significant undertaking - plan for iterative development
- Rich text editor is also significant - consider using existing libraries as reference (flutter_quill, etc.) but build custom for full control
- Keep components independent and testable
- Document component APIs clearly

## Future Considerations

- **Monorepo Tools**: Consider `melos` for managing multiple packages
- **Component Testing**: Set up testing infrastructure for each component
- **Component Documentation**: Generate API docs for each component
- **Version Management**: Establish versioning strategy for components
- **CI/CD**: Set up CI/CD for component packages
- **Plugin System**: Design plugin architecture (per PRD) that can use components

---

*This plan aligns with the PRD requirements and provides a scalable architecture for the Slote application.*