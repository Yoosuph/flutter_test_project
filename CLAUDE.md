# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile todo application featuring a modern, animated UI with gradient design. The app is currently Android-only (iOS, web, macOS, Linux, and Windows platform directories have been removed from version control).

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Clean build artifacts
flutter clean
```

### Running
```bash
# Run on Android device/emulator
flutter run

# Run with hot reload enabled (default)
flutter run

# Run in release mode
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/ test/

# Check formatting without modifying
dart format --output=none --set-exit-if-changed lib/ test/
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build app bundle for Play Store
flutter build appbundle

# Build debug APK
flutter build apk --debug
```

## Architecture

### Single-File Application Structure

The entire application is currently contained in `lib/main.dart` with the following architecture:

**Core Components:**
- `TodoApp` - Root MaterialApp widget with Material 3 theme and Google Fonts (Poppins)
- `TodoListPage` - Main stateful widget managing the todo list UI and state
- `Todo` - Simple data model with title, completion status, unique ID, and creation timestamp

**State Management:**
- Uses basic Flutter `setState()` for local state management
- No external state management libraries (no Provider, Riverpod, Bloc, etc.)
- Todo list stored in `_TodoListPageState._todos` as a `List<Todo>`
- No persistence layer - all data is in-memory and lost on app restart

**UI Architecture:**
- Gradient background header with stats display (total, completed, pending)
- Circular progress indicator showing completion percentage
- Input field with inline add button in a glass-morphism style container
- Scrollable todo list in a rounded white container
- Empty state with animated illustration and usage hints

**Key Features:**
- Swipe-to-delete using `flutter_slidable` package
- Tap to toggle completion
- Animations on todo item creation with staggered entrance
- Haptic feedback on interactions
- Time-based greeting message (morning/afternoon/evening)

### Dependencies

**Production:**
- `google_fonts: ^6.2.1` - Poppins font family for consistent typography
- `flutter_slidable: ^3.1.1` - Swipe gesture support for delete actions
- `cupertino_icons: ^1.0.8` - iOS-style icons

**Development:**
- `flutter_lints: ^6.0.0` - Recommended Flutter linting rules
- `flutter_test` - Widget testing framework

### Platform Support

**Active:** Android only (confirmed by directory structure)

**Removed from version control:** iOS, web, macOS, Linux, Windows platform directories have been deleted

When adding platform-specific features, only implement for Android unless explicitly requested otherwise.

## Code Patterns

### Widget Structure
- Uses Material 3 design (`useMaterial3: true`)
- Gradient backgrounds with `LinearGradient`
- Glass-morphism effect with semi-transparent white overlays
- Rounded corners (typically 16-20px border radius)
- Box shadows for depth

### Animation Patterns
- `TweenAnimationBuilder` for entrance animations with `Curves.easeOutBack`
- `AnimatedContainer` for state transitions (completion status changes)
- Staggered animations using index-based delays: `Duration(milliseconds: 300 + (index * 50))`
- `AnimationController` with `TickerProviderStateMixin` for complex animations

### Color Scheme
- Primary gradient: Purple-to-pink (`#667eea` → `#764ba2` → `#f093fb`)
- Background: Light gray (`#F8F9FA`)
- Text: Dark gray (`#2D3436`)
- Completed items: Gray tones

## Testing Notes

The current test file (`test/widget_test.dart`) contains a default counter increment test that does NOT match the actual application (which is a todo app, not a counter). This test will fail and should be updated to test the TodoApp functionality instead.

## Dart SDK Version

Minimum SDK: `^3.10.1`
