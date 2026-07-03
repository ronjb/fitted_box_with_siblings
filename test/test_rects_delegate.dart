import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/rendering.dart';

/// A test delegate that wraps a callback and always relayouts, matching the
/// behavior of the pre-delegate function-based API.
class TestRectsDelegate extends FittedBoxWithSiblingsDelegate {
  const TestRectsDelegate(this.rectsFor);

  final List<Rect> Function(BoxConstraints constraints, Size boxSize) rectsFor;

  @override
  List<Rect> computeRects(BoxConstraints constraints, Size boxSize) =>
      rectsFor(constraints, boxSize);

  @override
  bool shouldRelayout(TestRectsDelegate oldDelegate) => true;
}
