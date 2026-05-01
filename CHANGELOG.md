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
