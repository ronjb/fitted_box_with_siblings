# fitted_box_with_siblings

[![pub package](https://img.shields.io/pub/v/fitted_box_with_siblings.svg)](https://pub.dev/packages/fitted_box_with_siblings)

A Flutter widget that scales and positions a first child (the "box") within itself according to `BoxFit` (like `FittedBox`), while allowing additional sibling widgets to fill their own defined rectangles.

## Getting Started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fitted_box_with_siblings: ^0.0.1
```

## Usage

```dart
import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
```

`FittedBoxWithSiblings` takes a required `computeRects` callback and a list of `children`. The callback receives the parent's constraints and the first child's natural size, and returns a `List<Rect>` — one rect per child — defining where each child is placed.

The first child is the "fitted" child, scaled into its rect according to the `fit` property (defaults to `BoxFit.contain`). All subsequent children are siblings that fill their assigned rects.

```dart
FittedBoxWithSiblings(
  fit: BoxFit.contain,
  computeRects: (constraints, boxSize) {
    final centerX = constraints.maxWidth / 2;
    return [
      // Rect for the fitted child (scaled via BoxFit).
      Rect.fromLTWH(0, 100, constraints.maxWidth, constraints.maxHeight - 100),
      // Rect for the first sibling.
      Rect.fromLTWH(0, 0, centerX, 100),
      // Rect for the second sibling.
      Rect.fromLTWH(centerX, 0, centerX, 100),
    ];
  },
  children: [
    Text('Scaled to fit'),
    Container(color: Colors.yellow, child: Text('Left header')),
    Container(color: Colors.blue, child: Text('Right header')),
  ],
)
```

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `fit` | `BoxFit` | `BoxFit.contain` | How to inscribe the first child into its rect. |
| `alignment` | `AlignmentGeometry` | `Alignment.center` | How to align the first child within its rect. |
| `clipBehavior` | `Clip` | `Clip.none` | Whether and how to clip children that overflow. |
| `stackFit` | `StackFit` | `StackFit.loose` | How to size the first child before fitting. |
| `computeRects` | `RectsForFittedBoxWithSiblings` | required | Callback that returns rects for each child. |

## Add an Issue for Missing Features

If you find a bug or want a new feature, please [open an issue](https://github.com/ronjb/fitted_box_with_siblings/issues).
