/// RenderFittedBoxWithSiblings
/// @docImport 'fitted_box_with_siblings.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A delegate that computes the rects for the children of a
/// [FittedBoxWithSiblings].
///
/// Override [computeRects] to define where the fitted box and its siblings
/// are placed, and [shouldRelayout] to report whether a newly provided
/// delegate would produce different rects than the old one.
abstract class FittedBoxWithSiblingsDelegate {
  /// Abstract const constructor. This constructor enables subclasses to
  /// provide const constructors so that they can be used in const
  /// expressions.
  const FittedBoxWithSiblingsDelegate();

  /// Returns the rects for the fitted box and its siblings.
  ///
  /// The [constraints] are the constraints passed into the
  /// [FittedBoxWithSiblings] from its parent, as transformed by
  /// [FittedBoxWithSiblings.stackFit]. The [boxSize] is the natural size of
  /// the first child (the "box"), which is laid out unconstrained.
  ///
  /// The returned list must contain exactly one finite rect per child.
  ///
  /// When the box has a [WrapToFit] inside it, this is also called for each
  /// wrap width tried, and some 30 to 200 times with box sizes no layout
  /// gave, or about 350 for a rect that changes at nearly every shape of the
  /// box, to find the width that shows the box largest, so the rects should
  /// depend only on the arguments, and be cheap to compute.
  List<Rect> computeRects(BoxConstraints constraints, Size boxSize);

  /// Called whenever a new delegate instance is provided to the render
  /// object, e.g. when the [FittedBoxWithSiblings] widget rebuilds.
  ///
  /// Should return true if the new instance would produce different rects
  /// than [oldDelegate], and false otherwise. Returning false skips an
  /// unnecessary relayout.
  ///
  /// This is only called when the new instance has the same [runtimeType] as
  /// [oldDelegate]; a delegate of a different type always relayouts.
  bool shouldRelayout(covariant FittedBoxWithSiblingsDelegate oldDelegate);
}

/// The render object for [FittedBoxWithSiblings].
class RenderFittedBoxWithSiblings extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, StackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderFittedBoxWithSiblings({
    List<RenderBox>? children,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection? textDirection,
    StackFit stackFit = StackFit.loose,
    Clip clipBehavior = Clip.none,
    Axis? expandBox,
    required FittedBoxWithSiblingsDelegate delegate,
  }) : _fit = fit,
       _alignment = alignment,
       _textDirection = textDirection,
       _stackFit = stackFit,
       _clipBehavior = clipBehavior,
       _expandBox = expandBox,
       _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    if (_fit == value) {
      return;
    }
    // The fit affects the baseline of the first child, and with expandBox,
    // its layout, and with a WrapToFit, its wrap width.
    _fit = value;
    _wrapWidthStale = true;
    _clearPaintData();
    markNeedsLayout();
  }

  Alignment get _resolvedAlignment => _resolvedAlignmentCache ??= alignment
      .resolve(textDirection ?? TextDirection.ltr);
  Alignment? _resolvedAlignmentCache;

  void _markNeedResolution() {
    _resolvedAlignmentCache = null;
    _clearPaintData();
    markNeedsLayout();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    _markNeedResolution();
  }

  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _markNeedResolution();
  }

  StackFit get stackFit => _stackFit;
  StackFit _stackFit;
  set stackFit(StackFit value) {
    if (_stackFit != value) {
      _stackFit = value;
      _clearPaintData();
      markNeedsLayout();
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  /// See [FittedBoxWithSiblings.expandBox].
  Axis? get expandBox => _expandBox;
  Axis? _expandBox;
  set expandBox(Axis? value) {
    if (_expandBox != value) {
      _expandBox = value;
      _clearPaintData();
      markNeedsLayout();
    }
  }

  FittedBoxWithSiblingsDelegate get delegate => _delegate;
  FittedBoxWithSiblingsDelegate _delegate;
  set delegate(FittedBoxWithSiblingsDelegate value) {
    if (identical(_delegate, value)) {
      return;
    }
    final oldDelegate = _delegate;
    _delegate = value;
    if (value.runtimeType != oldDelegate.runtimeType ||
        value.shouldRelayout(oldDelegate)) {
      _wrapWidthStale = true;
      _clearPaintData();
      markNeedsLayout();
    }
  }

  @override
  void markNeedsLayout() {
    // Marking the WrapToFit texts for a new wrap width marks their ancestors
    // too, up to this, which is already laying them out.
    if (_markingWrapTexts) return;
    super.markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicDimension(
      firstChild,
      (child) => child.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicDimension(
      firstChild,
      (child) => child.getMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicDimension(
      firstChild,
      (child) => child.getMinIntrinsicHeight(width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicDimension(
      firstChild,
      (child) => child.getMaxIntrinsicHeight(width),
    );
  }

  static double _getIntrinsicDimension(
    RenderBox? firstChild,
    double Function(RenderBox child) mainChildSizeGetter,
  ) {
    var extent = 0.0;
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (!childParentData.isPositioned) {
        extent = math.max(extent, mainChildSizeGetter(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    var baselineOffset = BaselineOffset.noBaseline;
    var i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      // The first child is painted fitted into its rect, and siblings are
      // painted at the top left of their rect, which they fill. In release
      // mode a missing rect falls back to Rect.zero, matching performLayout.
      final rect = i < _rects.length ? _rects[i] : Rect.zero;
      final childBaseline = child.getDistanceToActualBaseline(baseline);
      if (childBaseline != null) {
        baselineOffset = baselineOffset.minOf(
          BaselineOffset(
            i == 0
                ? _boxBaseline(childBaseline, child.size, rect)
                : childBaseline + rect.top,
          ),
        );
      }
      i++;
    }
    return baselineOffset.offset;
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final result = _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
    );
    _checkRectCount(result.rects);

    var baselineOffset = BaselineOffset.noBaseline;
    var i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      // Mirror computeDistanceToActualBaseline, with the constraints that
      // performLayout applies: the first child is laid out with the box
      // constraints, and siblings are laid out with constraints tight to
      // their rect. In release mode a missing rect falls back to Rect.zero,
      // matching performLayout.
      final rect = i < result.rects.length ? result.rects[i] : Rect.zero;
      final childConstraints = i == 0
          ? result.boxConstraints
          : BoxConstraints.tight(rect.size);
      final childBaseline = child.getDryBaseline(childConstraints, baseline);
      if (childBaseline != null) {
        baselineOffset = baselineOffset.minOf(
          BaselineOffset(
            i == 0
                ? _boxBaseline(
                    childBaseline,
                    child.getDryLayout(childConstraints),
                    rect,
                  )
                : childBaseline + rect.top,
          ),
        );
      }
      i++;
    }
    return baselineOffset.offset;
  }

  /// The distance from the top of this render object to the baseline of the
  /// first child (the "box"), [childBaseline] below the top of the box, as
  /// the box of [childSize] is painted fitted into [boxRect], or null when
  /// the box paints nothing.
  double? _boxBaseline(double childBaseline, Size childSize, Rect boxRect) {
    if (childSize.isEmpty || boxRect.isEmpty) return null;
    final (:source, :destination) = _fitBox(childSize, boxRect);
    return destination.top +
        (childBaseline - source.top) * destination.height / source.height;
  }

  /// The part of the first child (the "box") of [childSize] that is painted,
  /// and where in [boxRect] it is painted, according to [fit] and
  /// [alignment].
  ({Rect source, Rect destination}) _fitBox(Size childSize, Rect boxRect) {
    final sizes = applyBoxFit(_fit, childSize, boxRect.size);
    final alignment = _resolvedAlignment;
    return (
      source: alignment.inscribe(sizes.source, Offset.zero & childSize),
      destination: alignment.inscribe(sizes.destination, boxRect),
    );
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final result = _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
    );
    _checkRectCount(result.rects);
    return result.size;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

    final result = _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.layoutChild,
      searchWrapWidth: true,
    );
    size = result.size;
    _rects = result.rects;

    // Validate after size is set, so a rect count mismatch surfaces as a
    // single descriptive error instead of cascading missing-size exceptions.
    _checkRectCount(_rects);

    var child = firstChild;
    var i = 0;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (childParentData.isPositioned) {
        throw UnimplementedError(
          'Positioned children are not supported in FittedBoxWithSiblings.',
        );
      } else {
        // Siblings fill their rect, so they are placed at its top left. The
        // first child is painted fitted into its rect by a transform instead,
        // so its offset is unused. The rect count is validated by
        // _checkRectCount above in debug mode; in release mode a missing rect
        // falls back to Rect.zero.
        final rect = i < _rects.length ? _rects[i] : Rect.zero;
        childParentData.offset = rect.topLeft;
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
      i++;
    }

    _clearPaintData();
  }

  /// Lays out the children, returning this render object's size, the rects
  /// from the [delegate], and the constraints the first child (the "box") was
  /// last laid out with.
  ///
  /// When [searchWrapWidth] is true, which only a real layout can do, the
  /// [WrapToFit] texts in the box wrap at the width that shows it largest.
  /// Otherwise they wrap at the width the last layout picked.
  ({Size size, List<Rect> rects, BoxConstraints boxConstraints}) _computeSize({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
    bool searchWrapWidth = false,
  }) {
    if (childCount == 0) {
      return (
        size: constraints.biggest.isFinite
            ? constraints.biggest
            : constraints.smallest,
        rects: [],
        boxConstraints: const BoxConstraints(),
      );
    }

    late List<Rect> rects;
    var boxConstraints = const BoxConstraints();

    final nonPositionedConstraints = switch (stackFit) {
      StackFit.loose => constraints.loosen(),
      StackFit.expand => BoxConstraints.tight(constraints.biggest),
      StackFit.passthrough => constraints,
    };

    var child = firstChild;
    var i = 0;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;

      if (childParentData.isPositioned) {
        throw UnimplementedError(
          'Positioned children are not supported in FittedBoxWithSiblings.',
        );
      } else if (identical(child, firstChild)) {
        final childSize = searchWrapWidth && _wrapTexts.isNotEmpty
            ? _layoutBoxWrapped(child, nonPositionedConstraints)
            : layoutChild(child, const BoxConstraints());
        rects = delegate.computeRects(nonPositionedConstraints, childSize);

        assert(() {
          if (!rects.every((r) => r.isFinite)) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                'The rects returned by computeRects must be finite.',
              ),
              ErrorDescription(
                'The rects returned were:\n'
                '$rects\n'
                'The constraints passed to computeRects were:\n'
                '$nonPositionedConstraints\n'
                'The boxSize passed to computeRects was:\n'
                '$childSize',
              ),
            ]);
          }
          return true;
        }());

        final expanded = _expandedBoxConstraints(childSize, rects);
        if (expanded != null) {
          boxConstraints = expanded;
          layoutChild(child, boxConstraints);
        }
      } else {
        // Fall back to Size.zero when computeRects returned too few rects, so
        // layout completes and the mismatch is reported as a single error by
        // _checkRectCount, without cascading missing-size exceptions.
        final rectSize = i < rects.length ? rects[i].size : Size.zero;
        layoutChild(child, BoxConstraints.tight(rectSize));
      }

      child = childParentData.nextSibling;
      i++;
    }

    // An empty rects list is a computeRects contract violation, reported by
    // _checkRectCount after layout completes; fall back to Size.zero here.
    final boundingSize = rects.isEmpty
        ? Size.zero
        : Size(rects.boundingRect.right, rects.boundingRect.bottom);
    final size = constraints.constrain(boundingSize);
    assert(size.isFinite);
    return (size: size, rects: rects, boxConstraints: boxConstraints);
  }

  /// The constraints that grow the box from [boxSize] along [expandBox] to
  /// fill its rect, the first of [rects], at the scale [fit] applies, or null
  /// when the box keeps its own size.
  BoxConstraints? _expandedBoxConstraints(Size boxSize, List<Rect> rects) {
    final axis = _expandBox;
    if (axis == null || boxSize.isEmpty || rects.isEmpty) return null;
    final rect = rects.first;
    if (rect.isEmpty) return null;

    // The destination size over the source size is the scale the fit applies
    // to the box, so the rect's extent over that scale fills the rect. The
    // cross axis is loose, because tight constraints would make the box a
    // relayout boundary, so a change inside it would stop at the box, and the
    // delegate would not see its new size.
    final sizes = applyBoxFit(_fit, boxSize, rect.size);
    switch (axis) {
      case Axis.horizontal:
        final width = rect.width / sizes.destination.width * sizes.source.width;
        return width > boxSize.width
            ? BoxConstraints(
                minWidth: width,
                maxWidth: width,
                maxHeight: boxSize.height,
              )
            : null;
      case Axis.vertical:
        final height =
            rect.height / sizes.destination.height * sizes.source.height;
        return height > boxSize.height
            ? BoxConstraints(
                maxWidth: boxSize.width,
                minHeight: height,
                maxHeight: height,
              )
            : null;
    }
  }

  // The WrapToFit texts this is the nearest RenderFittedBoxWithSiblings
  // above. Those inside the box wrap at the width the search picks.
  final _wrapTexts = <RenderWrapToFit>{};

  // The width the search last picked, or infinity for no wrapping, and the
  // room and box size it was picked for.
  double _wrapWidth = double.infinity;
  BoxConstraints? _wrapRoom;
  Size? _wrapBoxSize;

  // Whether a change other than to the room or the box's size could change
  // the width the search picks: to a text, the delegate, or the fit.
  bool _wrapWidthStale = true;

  // Whether the texts are being marked as needing layout for a new width.
  bool _markingWrapTexts = false;

  /// Lays out the [box] with no constraints, wrapping the [WrapToFit] texts
  /// inside it at the width that shows it largest in the [room], and returns
  /// its size.
  Size _layoutBoxWrapped(RenderBox box, BoxConstraints room) {
    // The width is kept while nothing it depends on changes, as on a clock
    // tick, which then costs one layout, as it would without wrapping.
    if (!_wrapWidthStale && room == _wrapRoom) {
      final size = ChildLayoutHelper.layoutChild(box, const BoxConstraints());
      if (size == _wrapBoxSize) return size;
    }

    // Anything that changes during the search counts for the next layout.
    _wrapWidthStale = false;
    _searchWrapWidth(box, room);
    _wrapRoom = room;
    return _wrapBoxSize = box.size;
  }

  /// Finds the widest wrap width at which the [box] shows largest in the
  /// [room], and leaves the box laid out at it.
  void _searchWrapWidth(RenderBox box, BoxConstraints room) {
    final previous = _wrapWidth;
    _wrapWidth = double.infinity;

    // Unwrapped first: where wrapping can't help, that's the layout. This
    // also unwraps a WrapToFit outside the box, which never wraps.
    _setWrapWidth(_wrapTexts, double.infinity);
    ChildLayoutHelper.layoutChild(box, const BoxConstraints());
    final texts = [
      for (final text in _wrapTexts)
        if (_isInBox(text)) text,
    ];

    // Only the fits that show the whole box can show more of it by wrapping.
    final maxScale = switch (_fit) {
      BoxFit.contain => double.infinity,
      BoxFit.scaleDown => 1.0,
      _ => null,
    };
    final roomSize = room.biggest;
    if (texts.isEmpty ||
        maxScale == null ||
        !roomSize.isFinite ||
        roomSize.isEmpty) {
      return;
    }

    Size layoutAt(double width) {
      _setWrapWidth(texts, width);
      return ChildLayoutHelper.layoutChild(box, const BoxConstraints());
    }

    _Trial measure(double width) {
      final size = layoutAt(width);
      // Every width from the widest line up gives the same lines.
      var floor = 0.0;
      for (final text in texts) {
        floor = math.max(floor, text._laidOutWidth);
      }
      var rectSize = Size.zero;
      var sx = 0.0;
      var sy = 0.0;
      if (!size.isEmpty) {
        final rect = delegate.computeRects(room, size).firstOrNull;
        if (rect != null && rect.isFinite && !rect.isEmpty) {
          rectSize = rect.size;
          sx = rect.width / size.width;
          sy = rect.height / size.height;
        }
      }
      return (
        w: width.isFinite ? width : floor,
        floor: math.min(width, floor),
        size: size,
        rect: rectSize,
        sx: sx,
        sy: sy,
        scale: math.min(maxScale, math.min(sx, sy)),
      );
    }

    // The widest width worth trying is the widest line unwrapped, and the
    // narrowest is the longest word, which the text keeps until it changes.
    final unwrapped = measure(double.infinity);
    final hi = unwrapped.floor;
    if (hi <= 1 || unwrapped.size.isEmpty || unwrapped.scale >= maxScale) {
      return;
    }
    var lo = 1.0;
    for (final text in texts) {
      lo = math.max(lo, text.getMinIntrinsicWidth(double.infinity));
    }
    lo = math.min(lo, hi);

    final trials = <double, _Trial>{hi: unwrapped};
    _Trial trial(double width) {
      final clamped = clampDouble(width, lo, hi);
      return trials[clamped] ??= measure(clamped);
    }

    // The box shows largest where it takes the shape of its rect, and the
    // rect can depend on the box's shape, as when the siblings go beside a
    // wide box and below a tall one. So aim for each shape, from the
    // narrowest the text can make the box to the unwrapped one, at which a
    // box shows larger than at the shapes either side of it, and lay the box
    // out at each to decide between them. Finding the shapes asks for the
    // rects of boxes with the unwrapped box's area, with no layout. Comparing
    // the scales of shapes far apart would rest on that area, which wrapping
    // changes: it adds to a box whose width another row sets, and takes from
    // one whose height another row sets.
    final area = unwrapped.size.width * unwrapped.size.height;
    _ShapeFit fitAt(double aspect) {
      final size = Size(math.sqrt(area * aspect), math.sqrt(area / aspect));
      final rect = delegate.computeRects(room, size).firstOrNull;
      return rect == null || !rect.isFinite || rect.isEmpty
          ? (excess: double.nan, scale: 0)
          : (
              excess: math.log(aspect * rect.height / rect.width),
              scale: math.min(
                rect.width / size.width,
                rect.height / size.height,
              ),
            );
    }

    final targets = _shapeTargets(trial(lo).aspect, unwrapped.aspect, fitAt);
    // Where the rect changes at nearly every shape, laying the box out at
    // every target would take a hundred layouts, so keep the few at which a
    // box of the unwrapped box's area shows largest. Wrapping changes that
    // area, but the layouts still decide between the ones kept.
    const maxTargets = 4;
    if (targets.length > maxTargets) {
      targets
        ..sort((a, b) => b.scale.compareTo(a.scale))
        ..length = maxTargets;
    }
    if (targets.isNotEmpty) {
      // Start from the last width, which a small change keeps close.
      if (previous > lo && previous < hi) trial(previous);
      for (final target in targets) {
        _findAspect(target.aspect, lo, maxScale, trials, trial);
      }
    }

    // The best scale, and the widest width that gets it.
    var best = unwrapped;
    for (final t in trials.values) {
      if (t.scale > best.scale || (t.scale == best.scale && t.w > best.w)) {
        best = t;
      }
    }

    // A fit that doesn't scale the box up does as well at every width at
    // which the box fits its rect unscaled, so look for the widest, between
    // the widest found and the narrowest found too wide.
    if (best.scale >= maxScale) {
      var tooWide = hi;
      for (final t in trials.values) {
        if (t.scale < maxScale && t.w > best.w) {
          tooWide = math.min(tooWide, t.floor);
        }
      }
      while (tooWide / best.w > 1.01) {
        final t = trial(math.sqrt(best.w * tooWide));
        if (t.scale >= maxScale) {
          best = t;
        } else {
          tooWide = t.floor;
        }
      }
    }

    // Where another row sets the box's width, the text can widen into the
    // room that row leaves it without changing the box.
    if (best.w < hi) {
      layoutAt(best.w);
      var roomy = best.w;
      // Reading the sizes of descendants is allowed in a layout callback.
      invokeLayoutCallback<BoxConstraints>(
        (_) => roomy = _widestWithoutWidening(box, texts, best.w),
      );
      if (roomy > best.w * 1.001) {
        final t = trial(roomy);
        if (t.scale >= best.scale) best = t;
      }
    }

    _wrapWidth = best.w < hi ? best.w : double.infinity;
    layoutAt(_wrapWidth);
  }

  /// The shapes, from the aspect ratios [narrowest] to [widest], at which a
  /// box shows larger than at the shapes either side of it, each with the
  /// scale its rect gives it, where [fitAt] gives how a box of a shape fits
  /// its rect.
  static List<_ShapeTarget> _shapeTargets(
    double narrowest,
    double widest,
    _ShapeFit Function(double aspect) fitAt,
  ) {
    final targets = <_ShapeTarget>[];
    if (!(narrowest < widest)) return targets;

    // A rect that follows the box's shape gives an excess of 0, give or take
    // rounding, so the comparisons allow for that.
    const tolerance = 1e-9;

    // The first shape from [a] to [b] at which [isPast] holds, to within a
    // thousandth of the way between them in log space, and the last before
    // it, each with how a box of it fits its rect, given [fitA] and [fitB]
    // for [a] and [b].
    ({double before, _ShapeFit fitBefore, double past, _ShapeFit fitPast})
    bisect(
      double a,
      _ShapeFit fitA,
      double b,
      _ShapeFit fitB,
      bool Function(double aspect, _ShapeFit fit) isPast,
    ) {
      var before = a;
      var fitBefore = fitA;
      var past = b;
      var fitPast = fitB;
      for (var i = 0; i < 10; i++) {
        final mid = math.sqrt(before * past);
        final fitMid = fitAt(mid);
        if (isPast(mid, fitMid)) {
          past = mid;
          fitPast = fitMid;
        } else {
          before = mid;
          fitBefore = fitMid;
        }
      }
      return (
        before: before,
        fitBefore: fitBefore,
        past: past,
        fitPast: fitPast,
      );
    }

    // Whether boxes of the shapes [a0] and [a1], with the excesses [e0] and
    // [e1], have the same rect: one whose shape stays the same, so the
    // excess grows with the box's shape, or one that follows the box's
    // shape, so the excess stays the same.
    bool sameRect(double a0, double e0, double a1, double e1) =>
        (e1 - e0 - math.log(a1 / a0)).abs() <= tolerance ||
        (e1 - e0).abs() <= tolerance;

    var a0 = narrowest;
    var f0 = fitAt(a0);
    // Even the narrowest box is no narrower than its rect.
    if (f0.excess >= -tolerance) targets.add((aspect: a0, scale: f0.scale));

    const steps = 32;
    final step = math.pow(widest / narrowest, 1 / steps);
    for (var i = 1; i <= steps; i++) {
      final a1 = narrowest * math.pow(step, i);
      final f1 = fitAt(a1);

      // Where the rect changes, the box shows largest just before the change
      // if it grows up to it, being no wider than its rect, and the new rect
      // shows it smaller. It shows largest just past the change if the new
      // rect shows it larger, and it shrinks from there, being no narrower
      // than the new rect. The two sides are the same shape, so comparing
      // their scales doesn't rest on the area.
      if (!f0.excess.isNaN &&
          !f1.excess.isNaN &&
          !sameRect(a0, f0.excess, a1, f1.excess)) {
        final start = a0;
        final startExcess = f0.excess;
        final (:before, :fitBefore, :past, :fitPast) = bisect(
          start,
          f0,
          a1,
          f1,
          (a, fit) => !sameRect(start, startExcess, a, fit.excess),
        );
        if (fitBefore.excess <= tolerance && fitBefore.scale >= fitPast.scale) {
          targets.add((aspect: before, scale: fitBefore.scale));
        }
        if (fitPast.excess >= -tolerance && fitPast.scale >= fitBefore.scale) {
          targets.add((aspect: past, scale: fitPast.scale));
        }
        a0 = past;
        f0 = fitPast;
      }

      if (f0.excess < -tolerance && f1.excess >= -tolerance) {
        final crossing = bisect(
          a0,
          f0,
          a1,
          f1,
          (a, fit) => fit.excess >= -tolerance,
        );
        targets.add((aspect: crossing.past, scale: crossing.fitPast.scale));
      }
      a0 = a1;
      f0 = f1;
    }
    return targets;
  }

  /// Narrows in on the wrap width at which the box's aspect ratio, which
  /// grows with the width, reaches [target], adding to [trials].
  static void _findAspect(
    double target,
    double lo,
    double maxScale,
    Map<double, _Trial> trials,
    _Trial Function(double width) trial,
  ) {
    // f(x) = ln(aspect / target) at x = ln(w) grows by 1 to 2 for each 1 x
    // grows: by 2 where the text sets the box's width as well as adding to
    // its height, by 1 where another row sets the width.
    double f(_Trial t) => math.log(t.aspect / target);

    // The widest trial narrower than the target, and the narrowest one at
    // least as wide, which the unwrapped box is.
    final below = trials.values.where((t) => f(t) < 0);
    var narrower = below.isEmpty
        ? null
        : below.reduce((p, t) => t.w > p.w ? t : p);
    var b = trials.values
        .where((t) => f(t) >= 0)
        .reduce((p, t) => t.w < p.w ? t : p);

    // Step down to a width narrower than the target. A slope of 1 oversteps
    // where it's 2, which is fine, since that's the side being looked for;
    // after one step, use the slope seen.
    _Trial? previousB;
    for (var i = 0; narrower == null && i < 4; i++) {
      var slope = 1.0;
      if (previousB != null) {
        final seen = (f(previousB) - f(b)) / math.log(previousB.w / b.w);
        if (seen.isFinite) slope = clampDouble(seen, 0.25, 3);
      }
      final guess = b.floor * math.exp(-f(b) / slope) * 0.98;
      final t = trial(math.max(lo, guess));
      if (f(t) < 0) {
        narrower = t;
      } else if (t.w <= lo) {
        return; // Even the narrowest is too wide.
      } else {
        previousB = b;
        b = t;
      }
    }
    if (narrower == null) {
      final t = trial(lo);
      if (f(t) >= 0) return;
      narrower = t;
    }

    var a = narrower;
    var fa = f(a);
    var fb = f(b);
    var side = 0;
    // Line breaks come in steps, so finer than 1% rarely finds another.
    // Every width from b's floor up gives b's lines, so the widths left to
    // look at lie between a and b's floor.
    for (var i = 0; i < 8 && b.floor / a.w > 1.01; i++) {
      // No width between a and b beats the scale a gets where only its width
      // limits it, or b where only its height does: stop once the best found
      // is that close. (Both must have the same rect, so the same siblings.)
      final sameRect =
          (a.rect.width - b.rect.width).abs() < 0.5 &&
          (a.rect.height - b.rect.height).abs() < 0.5;
      final bound = math.min(maxScale, math.min(a.sx, b.sy));
      if (sameRect && math.max(a.scale, b.scale) >= bound * 0.995) break;

      // Illinois: regula falsi in log space, halving a stuck end's weight.
      final xa = math.log(a.w);
      final xb = math.log(b.floor);
      var x = xb - fb * (xb - xa) / (fb - fa);
      // Keep clear of the ends, so a step in the text can't stall it.
      final margin = (xb - xa) * 0.05;
      x = clampDouble(x, xa + margin, xb - margin);
      final t = trial(math.exp(x));
      final ft = f(t);
      if (ft < 0) {
        a = t;
        fa = ft;
        if (side == -1) fb /= 2;
        side = -1;
      } else {
        b = t;
        fb = ft;
        if (side == 1) fa /= 2;
        side = 1;
      }
    }
  }

  /// The widest wrap width, from [width], at which none of the [texts] gets
  /// wider than the room its ancestors in the [box] leave it, so the box
  /// keeps its width.
  static double _widestWithoutWidening(
    RenderBox box,
    List<RenderWrapToFit> texts,
    double width,
  ) {
    var widest = double.infinity;
    for (final text in texts) {
      // A text can widen by the room each ancestor leaves beside it without
      // widening the box: a column wider than it, or a min width. A row or
      // padding widens with it.
      var room = 0.0;
      RenderBox node = text;
      while (node != box && node.parent is RenderBox) {
        final parent = node.parent! as RenderBox;
        if (!(parent is RenderFlex && parent.direction == Axis.horizontal) &&
            parent is! RenderPadding) {
          room += math.max(0, parent.size.width - node.size.width);
        }
        node = parent;
      }
      widest = math.min(widest, text.size.width + room);
    }
    return math.max(width, widest);
  }

  /// Whether [text] is inside the first child (the "box"), rather than a
  /// sibling.
  bool _isInBox(RenderObject text) {
    RenderObject? node = text;
    while (node != null && node.parent != this) {
      node = node.parent;
    }
    return node != null && identical(node, firstChild);
  }

  /// Has the [texts] wrap at [width], marking each that changes as needing
  /// layout, so laying out the box lays out only them again.
  void _setWrapWidth(Iterable<RenderWrapToFit> texts, double width) {
    // Marking a descendant is allowed in a layout callback, which is how
    // LayoutBuilder rebuilds its child.
    invokeLayoutCallback<BoxConstraints>((_) {
      _markingWrapTexts = true;
      try {
        for (final text in texts) {
          if (text._wrapWidth != width) {
            text
              .._wrapWidth = width
              ..markNeedsLayout();
          }
        }
      } finally {
        _markingWrapTexts = false;
      }
    });
  }

  /// In debug mode, throws a [FlutterError] if the number of rects returned
  /// by the delegate's `computeRects` method does not match the number of
  /// children. In release mode, missing rects fall back to [Size.zero] and
  /// extra rects expand the bounding box.
  void _checkRectCount(List<Rect> rects) {
    assert(() {
      if (rects.length != childCount) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The FittedBoxWithSiblingsDelegate.computeRects method must '
            'return a rect for every child.',
          ),
          ErrorDescription(
            'The number of rects returned by the delegate must match the '
            'number of the FittedBoxWithSiblings children.',
          ),
          ErrorHint(
            'The ${delegate.runtimeType} delegate returned ${rects.length} '
            'rects, but there are $childCount children.',
          ),
        ]);
      }
      return true;
    }());
  }

  var _rects = <Rect>[];
  bool? _hasVisualOverflow;
  Matrix4? _transform;

  void _clearPaintData() {
    _hasVisualOverflow = null;
    _transform = null;
  }

  /// Whether the first child (the "box") paints nothing, because its size is
  /// empty, or its rect is, which scales it to nothing. In release mode a
  /// missing rect counts as empty, matching the Rect.zero fallback in
  /// performLayout.
  bool get _boxPaintsNothing =>
      firstChild != null &&
      (firstChild!.size.isEmpty || (_rects.firstOrNull?.isEmpty ?? true));

  void _updatePaintData() {
    if (_transform != null) {
      return;
    }

    if (firstChild == null || _boxPaintsNothing) {
      // Siblings are still painted when the first child paints nothing, so
      // they can still overflow the bounds.
      _hasVisualOverflow = _siblingsOverflowBounds;
      _transform = Matrix4.identity();
    } else {
      final childSize = firstChild!.size;
      final (source: sourceRect, destination: destinationRect) = _fitBox(
        childSize,
        _rects[0],
      );
      final scaleX = destinationRect.width / sourceRect.width;
      final scaleY = destinationRect.height / sourceRect.height;
      // There is visual overflow if the fit crops the first child (the
      // source rect is smaller than the child), or if the first child's
      // destination rect or any sibling rect extends outside the bounds.
      _hasVisualOverflow =
          sourceRect.width < childSize.width ||
          sourceRect.height < childSize.height ||
          _overflowsBounds(destinationRect) ||
          _siblingsOverflowBounds;
      assert(scaleX.isFinite && scaleY.isFinite);
      _transform =
          Matrix4.translationValues(
              destinationRect.left,
              destinationRect.top,
              0.0,
            )
            ..scaleByDouble(scaleX, scaleY, 1.0, 1)
            ..translateByDouble(-sourceRect.left, -sourceRect.top, 0, 1);
      assert(_transform!.storage.every((value) => value.isFinite));
    }
  }

  /// Whether the given rect paints outside this render object's bounds.
  ///
  /// Empty rects paint nothing, so they never overflow.
  bool _overflowsBounds(Rect rect) =>
      !rect.isEmpty &&
      (rect.left < 0 ||
          rect.top < 0 ||
          rect.right > size.width ||
          rect.bottom > size.height);

  /// Whether any sibling rect paints outside this render object's bounds.
  ///
  /// Siblings are laid out with constraints tight to their rect, so the rect
  /// is exactly where each sibling paints.
  bool get _siblingsOverflowBounds => _rects.skip(1).any(_overflowsBounds);

  void _paintFirstChild(PaintingContext context, Offset offset) {
    final child = firstChild;
    if (child == null) {
      return;
    }
    context.paintChild(child, offset);
  }

  TransformLayer? _paintFirstChildWithTransform(
    PaintingContext context,
    Offset offset,
  ) {
    final childOffset = MatrixUtils.getAsTranslation(_transform!);
    if (childOffset == null) {
      return context.pushTransform(
        needsCompositing,
        offset,
        _transform!,
        _paintFirstChild,
        oldLayer: layer is TransformLayer ? layer! as TransformLayer : null,
      );
    } else {
      _paintFirstChild(context, offset + childOffset);
    }
    return null;
  }

  TransformLayer? _paintFittedBoxWithSiblings(
    PaintingContext context,
    Offset offset,
  ) {
    TransformLayer? layer;
    final skipFirstChild = _boxPaintsNothing;
    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (identical(child, firstChild)) {
        if (!skipFirstChild) {
          layer = _paintFirstChildWithTransform(context, offset);
        }
      } else {
        context.paintChild(child, childParentData.offset + offset);
      }
      child = childParentData.nextSibling;
    }

    return layer;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null || size.isEmpty) {
      return;
    }
    _updatePaintData();

    if (clipBehavior != Clip.none && _hasVisualOverflow == true) {
      layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintFittedBoxWithSiblings,
        clipBehavior: clipBehavior,
        oldLayer: layer is ClipRectLayer ? layer! as ClipRectLayer : null,
      );
    } else {
      layer = _paintFittedBoxWithSiblings(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null || size.isEmpty) {
      return false;
    }

    final skipFirstChild = _boxPaintsNothing;
    var child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      final bool isHit;

      if (identical(child, firstChild)) {
        if (skipFirstChild) {
          isHit = false;
        } else {
          _updatePaintData();
          isHit = result.addWithPaintTransform(
            transform: _transform,
            position: position,
            hitTest: (result, position) =>
                child!.hitTest(result, position: position),
          );
        }
      } else {
        // The x, y parameters have the top left of the box as the origin.
        isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (result, transformed) {
            assert(transformed == position - childParentData.offset);
            return child!.hitTest(result, position: transformed);
          },
        );
      }

      if (isHit) {
        return true;
      }

      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  bool paintsChild(RenderBox child) {
    assert(child.parent == this);
    if (size.isEmpty) return false;
    if (identical(child, firstChild)) {
      return !_boxPaintsNothing;
    } else {
      return super.paintsChild(child);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (identical(child, firstChild)) {
      if (!paintsChild(child)) {
        transform.setZero();
      } else {
        _updatePaintData();
        transform.multiply(_transform!);
      }
    } else {
      return super.applyPaintTransform(child, transform);
    }
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasVisualOverflow == true ? Offset.zero & size : null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<BoxFit>('fit', fit))
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(EnumProperty<TextDirection>('textDirection', textDirection))
      ..add(EnumProperty<StackFit>('stackFit', stackFit))
      ..add(
        EnumProperty<Clip>(
          'clipBehavior',
          clipBehavior,
          defaultValue: Clip.none,
        ),
      )
      ..add(EnumProperty<Axis>('expandBox', expandBox, defaultValue: null));
  }
}

/// The render object for [WrapToFit].
class RenderWrapToFit extends RenderProxyBox {
  /// Creates a render object that lays out its [child] no wider than the
  /// wrap width the nearest [RenderFittedBoxWithSiblings] above it picks.
  RenderWrapToFit({RenderBox? child}) : super(child);

  // The nearest RenderFittedBoxWithSiblings above this.
  RenderFittedBoxWithSiblings? _scope;

  // The width the scope has this wrap at.
  double _wrapWidth = double.infinity;

  // The width this was last laid out at, which the scope reads mid-layout,
  // where it may not ask a descendant for its size.
  double _laidOutWidth = 0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var node = parent;
    while (node != null && node is! RenderFittedBoxWithSiblings) {
      node = node.parent;
    }
    _scope = node as RenderFittedBoxWithSiblings?;
    _scope
      ?.._wrapTexts.add(this)
      .._wrapWidthStale = true;
    // Start unwrapped: a width picked where this was before doesn't hold
    // here, and only the scope's search picks another, for a text in its box.
    if (_wrapWidth.isFinite) {
      _wrapWidth = double.infinity;
      markNeedsLayout();
    }
  }

  @override
  void detach() {
    _scope
      ?.._wrapTexts.remove(this)
      .._wrapWidthStale = true;
    _scope = null;
    super.detach();
  }

  @override
  void markNeedsLayout() {
    // A change inside this can change the width that shows the box largest,
    // when this is in the box: one in a sibling never wraps.
    final scope = _scope;
    if (scope != null && !scope._markingWrapTexts && scope._isInBox(this)) {
      scope._wrapWidthStale = true;
    }
    super.markNeedsLayout();
  }

  // Sized as it lays out, no wider than the wrap width, so a parent that
  // sizes it by these, such as an IntrinsicWidth, lets it wrap.
  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.min(super.computeMaxIntrinsicWidth(height), _wrapWidth);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(math.min(width, _wrapWidth));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(math.min(width, _wrapWidth));

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      child?.getDryLayout(_wrapped(constraints)) ?? constraints.smallest;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_wrapped(constraints), baseline);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child.layout(_wrapped(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
    }
    _laidOutWidth = size.width;
  }

  BoxConstraints _wrapped(BoxConstraints constraints) => constraints.copyWith(
    maxWidth: math.max(
      constraints.minWidth,
      math.min(constraints.maxWidth, _wrapWidth),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DoubleProperty('wrapWidth', _wrapWidth, defaultValue: double.infinity),
    );
  }
}

/// One layout of the box at the wrap width `w`, where `floor` is the
/// narrowest width that gives the same lines, the widest line, `rect` is the
/// size of the box's rect, `sx` and `sy` are the scales the rect's width and
/// height would give the box, and `scale` is the scale the fit gives it.
typedef _Trial = ({
  double w,
  double floor,
  Size size,
  Size rect,
  double sx,
  double sy,
  double scale,
});

extension on _Trial {
  double get aspect => size.width / size.height;
}

/// How a box of a shape fits its rect: `excess` is the log of the box's
/// aspect ratio over its rect's, or NaN for no rect, and `scale` is the
/// smaller of the scales the rect's width and height would give the box.
typedef _ShapeFit = ({double excess, double scale});

/// A shape the search aims for: the box's aspect ratio there, and the scale
/// its rect gives a box of the unwrapped box's area.
typedef _ShapeTarget = ({double aspect, double scale});

extension on Iterable<Rect> {
  Rect get boundingRect {
    if (isEmpty) {
      throw ArgumentError('Cannot compute bounding rect of an empty list');
    }
    var left = first.left;
    var top = first.top;
    var right = first.right;
    var bottom = first.bottom;
    for (final r in skip(1)) {
      if (r.left < left) left = r.left;
      if (r.top < top) top = r.top;
      if (r.right > right) right = r.right;
      if (r.bottom > bottom) bottom = r.bottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
