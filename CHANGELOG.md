## 2.1.0

* Added `expandBox`. When set to an `Axis`, the first child (the "box") is laid out again after `computeRects`, grown along that axis to fill its rect at the scale the `fit` applies, so a box that can grow, such as a `Column` with `MainAxisSize.max` and `MainAxisAlignment.spaceEvenly`, fills its rect instead of leaving space beside it. It has no effect when the `fit` already fills the rect along that axis, such as `BoxFit.cover`. `computeRects` still receives the box's natural size, and the rects are not recomputed.
* Fix: the baseline of the first child (the "box") is now reported where it is painted, scaled and positioned by the `fit`, so the box lines up with its neighbors in a baseline-aligned `Row`. Previously it was reported at the box's unscaled size, which was only correct at a scale of 1. A first child that paints nothing, because its size or rect is empty, no longer reports a baseline.
* Fix: a first child whose rect is empty no longer fails a debug assertion when painted or hit-tested. Like a first child with an empty size, it is not painted.

## 2.0.0

* **BREAKING**: Replaced the `computeRects` callback with a `delegate` of type `FittedBoxWithSiblingsDelegate`, which has a `computeRects` method and a `shouldRelayout` method. Rebuilding with an equivalent delegate (same `runtimeType`, `shouldRelayout` returns false) no longer triggers an unnecessary relayout on every rebuild. To migrate, move your callback body into a delegate subclass:

  ```dart
  class MyDelegate extends FittedBoxWithSiblingsDelegate {
    const MyDelegate();

    @override
    List<Rect> computeRects(BoxConstraints constraints, Size boxSize) => [...];

    @override
    bool shouldRelayout(MyDelegate oldDelegate) => false;
  }
  ```

* Fix: `clipBehavior` now clips siblings (and the fitted child's destination) that extend outside the widget's bounds, not just fit-cropped content.
* Fix: `computeRects` returning an empty list or too many rects now reports a single descriptive `FlutterError` (previously an internal `ArgumentError` or silent acceptance); too few rects no longer cascades secondary exceptions, and dry layout reports the same error as real layout.
* Fix: the dry baseline now matches the actual baseline (it previously used `Stack`-style positioning logic that ignored the computed rects).
* Docs: corrected the `stackFit` documentation (it transforms the constraints passed to `computeRects`; the first child is always laid out unconstrained) and documented the intrinsic-dimensions approximation.

## 1.0.0

* First stable release.
* Expanded README with a "Why use this package?" section.
* Updated package description.

## 0.1.0

* Initial release.
* `FittedBoxWithSiblings` widget that scales a first child like `FittedBox` while positioning sibling widgets at computed rects.
* `computeRects` callback receives constraints and the first child's natural size, returns a `List<Rect>` for all children.
* Supports `BoxFit`, `Alignment`, `StackFit`, and `Clip` properties.
* Fix: siblings are now painted and hit-tested even when the fitted child has an empty size.
* Fix: render object default alignment matches widget default (`Alignment.center`).
