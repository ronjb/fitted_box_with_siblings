# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flutter package that provides `FittedBoxWithSiblings`, a widget that scales and positions a first child (the "box") within itself according to `BoxFit` (like `FittedBox`), while allowing additional sibling widgets to fill their own defined rectangles.

## Commands

```bash
flutter test                          # Run all tests
flutter test test/widgets/            # Run widget tests only
flutter test test/rendering/          # Run rendering tests only
flutter test test/path/to/file.dart   # Run a single test file
flutter analyze                       # Static analysis (strict mode enabled)
dart format .                         # Format all Dart files
```

## Architecture

The package has two core files in `lib/src/`:

- **`fitted_box_with_siblings.dart`** — `FittedBoxWithSiblings` widget, a `MultiChildRenderObjectWidget`. Takes a required `computeRects` callback (`RectsForFittedBoxWithSiblings` typedef) that receives constraints and the first child's size, returning a `List<Rect>` defining where each child should be placed.

- **`render_fitted_box_with_siblings.dart`** — `RenderFittedBoxWithSiblings`, the render object (`RenderBox` with `ContainerRenderObjectMixin`). Handles layout, painting with transforms, clipping, and transform-aware hit testing. Uses lazy paint data computation (`_updatePaintData`) for the transform matrix.

The first child is the "fitted" child (scaled via `BoxFit`), and all subsequent children are siblings positioned at their computed rects.

## Testing

- **`test/widgets/`** — Widget-level tests using standard `flutter_test` (`fitted_box_test.dart`, `stack_test.dart`)
- **`test/rendering/`** — Render object tests using a custom `TestRenderingFlutterBinding` in `rendering_tester.dart` (adapted from Flutter's test infrastructure)

## Code Style

- Strict analysis: `strict-casts`, `strict-inference`, and `strict-raw-types` are all enabled
- Lints from `flutter_lints_plus` package
- Comments that are complete sentences end with a period
- Public classes at top of file, private helpers below
