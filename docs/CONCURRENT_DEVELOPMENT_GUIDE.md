# Concurrent Development Guide

## Overview

This guide explains how multiple developers can work on different components simultaneously (e.g., Person A on `slote_rich_text`, Person B on `slote_viewport`) and merge their changes effectively.

## Component-Based Architecture Benefits

With the new component-based structure, concurrent development is **highly feasible** and **recommended**. Here's why:

### 1. Independent Development

Each component (`slote_viewport`, `slote_rich_text`, `slote_undo_redo`, `slote_draw`, `slote_theme`) is:
- **Self-contained**: Has its own directory, `pubspec.yaml`, and dependencies
- **Isolated**: Changes to one component don't affect others
- **Versioned independently**: Can be developed and tested separately

### 2. Clear Boundaries

```
components/
├── slote_viewport/      ← Person B works here
│   ├── lib/
│   └── pubspec.yaml
├── slote_rich_text/     ← Person A works here
│   ├── lib/
│   └── pubspec.yaml
└── ...
```

## Development Workflow

### Scenario: Person A (Rich Text) + Person B (Viewport)

#### Step 1: Initial Setup
```bash
# Both developers clone the repos
git clone <slote_app_repo>
git clone <components_repo>

# Both set up dependencies
cd <repo_root> && flutter pub get
cd components/rich_text && flutter pub get
cd ../viewport && flutter pub get
```

#### Step 2: Create Feature Branches
```bash
# Person A
cd components
git checkout -b feature/rich-text-editor
cd slote_rich_text
# Start developing...

# Person B
cd components
git checkout -b feature/viewport-improvements
cd slote_viewport
# Start developing...
```

#### Step 3: Independent Development

**Person A (slote_rich_text):**
- Works in `components/rich_text/`
- Can test independently (create test app or use example)
- Doesn't need to pull Person B's changes
- Can commit frequently to their branch

**Person B (slote_viewport):**
- Works in `components/viewport/`
- Can test independently
- Doesn't need to pull Person A's changes
- Can commit frequently to their branch

#### Step 4: Testing in Isolation

Each developer can create a simple test app:

**Person A's test app:**
```dart
// test_rich_text/lib/main.dart
import 'package:slote_rich_text/slote_rich_text.dart';

void main() {
  // Test rich text editor
}
```

**Person B's test app:**
```dart
// test_viewport/lib/main.dart
import 'package:slote_viewport/slote_viewport.dart';

void main() {
  // Test viewport
}
```

#### Step 5: Integration Testing (Common Ground)

**Option A: Integration Branch**
```bash
# Create integration branch from main
git checkout main
git checkout -b integration/rich-text-viewport

# Merge both feature branches
git merge feature/rich-text-editor
git merge feature/viewport-improvements

# Test together in the main app (repo root)
cd <repo_root>
flutter pub get
flutter run
```

**Option B: Staging Environment**
- Maintain a `staging` branch that combines all feature branches
- Regularly merge feature branches for integration testing
- Use CI/CD to automatically test combinations

#### Step 6: Merge to Main

Once both features are tested individually and together:

```bash
# Merge Person A's work
git checkout main
git merge feature/rich-text-editor

# Merge Person B's work
git merge feature/viewport-improvements

# Resolve any conflicts (should be minimal due to isolation)
```

## Common Ground for Testing

### 1. Integration Test App

Create a dedicated integration test in the main app (repo root):

```dart
// lib/src/views/integration_test.dart
import 'package:slote_rich_text/slote_rich_text.dart';
import 'package:slote_viewport/slote_viewport.dart';

class IntegrationTestView extends StatelessWidget {
  // Test both components together
}
```

### 2. Component Test Suites

Each component should have its own test suite:

```dart
// slote_rich_text/test/rich_text_test.dart
void main() {
  test('Rich text editor formats text correctly', () {
    // Test rich text
  });
}

// slote_viewport/test/viewport_test.dart
void main() {
  test('Viewport zooms correctly', () {
    // Test viewport
  });
}
```

### 3. Integration Tests

Create integration tests that test components together:

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Rich text in viewport works', (tester) async {
    // Test both together
  });
}
```

### 4. Shared Mock Data

Create shared test data that both developers can use:

```dart
// slote_shared/lib/src/test_utils/mock_data.dart
class MockData {
  static Note get sampleNote => Note(...);
  static String get sampleText => '...';
}
```

## Conflict Resolution

### When Conflicts Occur

Conflicts are **rare** because:
- Components are in separate directories
- Each has its own `pubspec.yaml`
- Dependencies are isolated

### If Conflicts Do Occur

**Scenario 1: Both modify root `pubspec.yaml`**
```yaml
# Conflict in dependencies section
dependencies:
  slote_rich_text:    # Person A added
    path: components/rich_text
  slote_viewport:     # Person B added
    path: components/viewport
```

**Resolution**: Both changes are compatible, just keep both.

**Scenario 2: Both modify shared files**
- If both modify `slote_shared`, coordinate or use feature flags
- Consider splitting `slote_shared` further if conflicts are frequent

## Best Practices

### 1. Communication
- **Daily standups**: Share progress and blockers
- **Slack/Discord**: Quick questions and updates
- **Pull Requests**: Review each other's code before merging

### 2. Branch Strategy
```
main (stable)
├── feature/rich-text-editor (Person A)
├── feature/viewport-improvements (Person B)
└── integration/staging (combined features)
```

### 3. Testing Strategy
- **Unit tests**: Each component tests itself
- **Integration tests**: Test components together
- **Manual testing**: Regular integration testing in the main app (repo root)

### 4. Dependency Management
- **Minimize cross-component dependencies**: Only when necessary
- **Use `slote_shared`**: For truly shared utilities
- **Version components**: Use semantic versioning

### 5. Documentation
- **Component README**: Each component should have a README
- **API Documentation**: Document public APIs
- **Integration Guide**: How to use components together

## Example: Concurrent Development Session

### Day 1: Setup
- Both developers clone repos
- Create feature branches
- Set up development environment

### Day 2-5: Independent Development
- Person A: Implements rich text formatting
- Person B: Implements viewport zoom/pan
- Both commit to their branches daily

### Day 6: Integration Testing
- Merge both branches to integration branch
- Test in the main app (repo root)
- Fix any integration issues

### Day 7: Merge to Main
- Both features tested and working
- Merge to main
- Deploy/Release

## Tools for Collaboration

### 1. Git
- **Feature branches**: Isolate work
- **Pull requests**: Code review
- **Merge commits**: Preserve history

### 2. CI/CD
- **Automated testing**: Run tests on every commit
- **Integration tests**: Test component combinations
- **Build verification**: Ensure app builds with changes

### 3. Project Management
- **GitHub Projects / Jira**: Track tasks
- **Milestones**: Plan releases
- **Labels**: Categorize issues

## Common Ground Summary

✅ **Yes, you can develop individually!**

**Common Ground:**
1. **Integration branch**: Merge both features for testing
2. **Main app (repo root)**: Where components are integrated
3. **Integration tests**: Automated tests for component combinations
4. **Shared test data**: Mock data in `slote_shared`
5. **Regular sync**: Daily/weekly integration testing

**Benefits:**
- ✅ Independent development
- ✅ Minimal conflicts
- ✅ Faster iteration
- ✅ Better code quality (focused work)
- ✅ Easier code review

**Workflow:**
1. Work independently on your component
2. Test your component in isolation
3. Regularly merge to integration branch
4. Test together in the main app (repo root)
5. Merge to main when ready

---

*This architecture enables true concurrent development while maintaining code quality and integration.*

