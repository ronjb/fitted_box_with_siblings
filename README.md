# fitted_box_with_siblings

[![pub package](https://img.shields.io/pub/v/fitted_box_with_siblings.svg)](https://pub.dev/packages/fitted_box_with_siblings)

A Flutter widget that scales and positions a first child (the "box") within itself according to `BoxFit` (like `FittedBox`), while allowing additional sibling widgets to fill their own defined rectangles.

## Why use this package?

`FittedBox` scales a child to fit, and `Stack` lets you layer widgets — but neither lets a sibling's position depend on the scaled child's *actual* laid-out rect. With `FittedBoxWithSiblings`, your delegate's `computeRects` method receives the parent's constraints **and** the first child's natural size, so you can lay out siblings relative to where the box will end up after `BoxFit` scaling.

Reach for it when you want to:

- Put a header, footer, or toolbar alongside a `BoxFit.contain` image and have the image fill the leftover space exactly.
- Place overlays, badges, or annotations whose position depends on the scaled box's bounds (not the parent's bounds).
- Build composite layouts where one child drives the geometry of the rest, without manually measuring with `LayoutBuilder` + `Stack`.

If you only need to scale a single child, use `FittedBox`. If you need free-form layering without geometry sharing, use `Stack`. This widget fills the gap between them.

## Getting Started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fitted_box_with_siblings: ^2.2.0
```

## Usage

```dart
import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
```

`FittedBoxWithSiblings` takes a required `delegate` — a subclass of `FittedBoxWithSiblingsDelegate` — and a list of `children`. The delegate's `computeRects` method receives the parent's constraints and the first child's natural size, and returns a `List<Rect>` — one rect per child — defining where each child is placed.

The first child is the "fitted" child, scaled into its rect according to the `fit` property (defaults to `BoxFit.contain`). All subsequent children are siblings that fill their assigned rects.

```dart
class HeaderAndBoxDelegate extends FittedBoxWithSiblingsDelegate {
  const HeaderAndBoxDelegate();

  @override
  List<Rect> computeRects(BoxConstraints constraints, Size boxSize) {
    final centerX = constraints.maxWidth / 2;
    return [
      // Rect for the fitted child (scaled via BoxFit).
      Rect.fromLTWH(0, 100, constraints.maxWidth, constraints.maxHeight - 100),
      // Rect for the first sibling.
      Rect.fromLTWH(0, 0, centerX, 100),
      // Rect for the second sibling.
      Rect.fromLTWH(centerX, 0, centerX, 100),
    ];
  }

  // The rects depend only on the constraints and box size passed to
  // computeRects, so an equivalent new instance never needs a relayout.
  @override
  bool shouldRelayout(HeaderAndBoxDelegate oldDelegate) => false;
}

// ...

FittedBoxWithSiblings(
  fit: BoxFit.contain,
  delegate: const HeaderAndBoxDelegate(),
  children: [
    Text('Scaled to fit'),
    Container(color: Colors.yellow, child: Text('Left header')),
    Container(color: Colors.blue, child: Text('Right header')),
  ],
)
```

If your rects depend on state outside the delegate, pass that state in through the delegate's constructor and compare it in `shouldRelayout`, returning true when it changed.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `fit` | `BoxFit` | `BoxFit.contain` | How to inscribe the first child into its rect. |
| `alignment` | `AlignmentGeometry` | `Alignment.center` | How to align the first child within its rect. |
| `clipBehavior` | `Clip` | `Clip.none` | Whether and how to clip children that overflow. |
| `stackFit` | `StackFit` | `StackFit.loose` | How to transform the constraints passed to `computeRects`. |
| `expandBox` | `Axis?` | `null` | After `computeRects`, grows the first child along this axis to fill its rect at the scale the `fit` applies, so a child that can grow, such as a `Column` with `MainAxisSize.max`, fills its rect. |
| `delegate` | `FittedBoxWithSiblingsDelegate` | required | Delegate whose `computeRects` method returns rects for each child. |

### Wrapping text to fit

The box is laid out with no constraints, so a long line of text in it stays one line, and makes the whole box small. Put the text inside a `WrapToFit` to let it wrap where that shows the box larger:

```dart
FittedBoxWithSiblings(
  delegate: const HeaderAndBoxDelegate(),
  children: [
    Column(
      children: [
        const Text('12:34', style: TextStyle(fontSize: 48)),
        const WrapToFit(
          child: Text(
            'Ann Cole, Ben Diaz, Cal Evans, Dee Fox, Eli Grant, Fay Hall',
            textAlign: TextAlign.center,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
      ],
    ),
    Container(color: Colors.yellow, child: Text('Left header')),
    Container(color: Colors.blue, child: Text('Right header')),
  ],
)
```

`FittedBoxWithSiblings` tries wrap widths during layout, and keeps the widest one that gives the box the largest scale in the rect your delegate returns for it. Where another part of the box sets its width, like the clock above, the text wraps at that width. Each try lays out only the `WrapToFit` widgets and the widgets around them again, and picking a width takes up to about 25 tries. The width is kept until the text, the constraints, the delegate, the fit, or the box's size changes, so a change elsewhere in the box that keeps its size, like the clock ticking, costs one layout, as it would without wrapping. A room that changes size every frame, as in an animation, picks it every frame.

- Give a `Text` `TextWidthBasis.longestLine`, so the search can skip the widths that give the same lines.
- Your delegate's `computeRects` is called for each width tried, up to about 25 times a layout, so its rects should depend only on its arguments. To skip widths that can't show the box larger, the search assumes the box's rect lies within the room, and that where `computeRects` returns the same rect for the box at two widths, it returns that rect at the widths between them.
- `WrapToFit` wraps only inside the box, only with `BoxFit.contain` or `BoxFit.scaleDown`, and only when the `FittedBoxWithSiblings` has bounded constraints. With `BoxFit.scaleDown`, it wraps only as much as the box needs to fit unscaled.

## Add an Issue for Missing Features

If you find a bug or want a new feature, please [open an issue](https://github.com/ronjb/fitted_box_with_siblings/issues).
