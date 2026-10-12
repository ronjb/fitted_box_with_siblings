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
  /// wrap width tried, up to about 25 times a layout, to find the width that
  /// shows the box largest, so the rects should depend only on the
  /// arguments. To skip widths that can't show the box larger, the search
  /// assumes the box's rect lies within `constraints.biggest`, and that where
  /// this returns the same rect for the box at two widths, it returns that
  /// rect at the widths between them.
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
  ///
  /// Narrowing the width never makes the box wider or shorter. So between
  /// two widths tried, the box is no narrower than at the narrower one, and
  /// no shorter than at the wider one, which bounds how large the room, or
  /// the rect the delegate gave at both, if it gave the same one, could show
  /// it there. This tries the widths between the two that could show it
  /// largest, until no two could beat the best found, or it has tried about
  /// 25.
  void _searchWrapWidth(RenderBox box, BoxConstraints room) {
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

    // The layouts tried, from the narrowest.
    final trials = <_Trial>[];
    _Trial trial(double width) {
      _setWrapWidth(texts, width);
      final size = ChildLayoutHelper.layoutChild(box, const BoxConstraints());
      var floor = 0.0;
      for (final text in texts) {
        floor = math.max(floor, text._laidOutWidth);
      }
      floor = math.min(floor, width);
      final rect = size.isEmpty
          ? null
          : delegate.computeRects(room, size).firstOrNull;
      final fits = rect != null && rect.isFinite && !rect.isEmpty;
      final t = (
        w: width,
        floor: floor,
        size: size,
        rect: fits ? rect.size : Size.zero,
        scale: fits
            ? math.min(
                maxScale,
                math.min(rect.width / size.width, rect.height / size.height),
              )
            : 0.0,
      );

      // Every width from a layout's widest line up to the widest width tried
      // that gave it gives the same lines.
      final i = trials.indexWhere((other) => other.floor >= floor);
      if (i < 0) {
        trials.add(t);
      } else if (trials[i].floor != floor) {
        trials.insert(i, t);
      } else if (width > trials[i].w) {
        trials[i] = t;
      }
      return t;
    }

    // The widest width worth trying is the widest line unwrapped, and the
    // narrowest is the longest word.
    final unwrapped = trial(double.infinity);
    var lo = 1.0;
    for (final text in texts) {
      lo = math.max(lo, text.getMinIntrinsicWidth(double.infinity));
    }
    if (unwrapped.size.isEmpty ||
        unwrapped.scale >= maxScale ||
        lo >= unwrapped.floor) {
      return;
    }
    trial(lo);

    // The layout with the largest scale, and of those, the widest lines.
    _Trial best() => trials.reduce(
      (best, t) =>
          t.scale > best.scale ||
              (t.scale == best.scale && t.floor > best.floor)
          ? t
          : best,
    );

    // Where the rect changes between most widths, every line break could
    // beat the best, so the search stops after about 25 layouts.
    for (var tries = 2; tries < 25; tries++) {
      final most = best();
      var split = double.nan;
      var splitBound = double.negativeInfinity;
      for (var i = 0; i + 1 < trials.length; i++) {
        final narrower = trials[i];
        final wider = trials[i + 1];
        // Lines within half a pixel show the box at nearly the same scale.
        if (wider.floor - narrower.w < 0.5) continue;

        final rect = narrower.rect == wider.rect ? narrower.rect : roomSize;
        final bound = math.min(
          maxScale,
          math.min(
            rect.width / narrower.size.width,
            rect.height / wider.size.height,
          ),
        );
        // The widths between are wider than the narrower one, so they win a
        // tie with it, or with any narrower one.
        final couldBeat =
            bound > most.scale ||
            (bound == most.scale && narrower.floor >= most.floor);
        if (couldBeat && bound > splitBound) {
          splitBound = bound;
          split = math.sqrt(narrower.w * wider.floor);
        }
      }
      if (split.isNaN) break;
      trial(split);
    }

    _wrapWidth = best().w;
    _setWrapWidth(texts, _wrapWidth);
    ChildLayoutHelper.layoutChild(box, const BoxConstraints());
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
    // LayoutBuilder rebuilds its child. The marks reach this, clearing its
    // cached intrinsic sizes, which depend on the wrap width, but the
    // callback keeps them from going above it.
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
/// narrowest width that gives the same lines, the widest line, `rect` is
/// the size of the box's rect, and `scale` is the scale the fit gives the
/// box in it.
typedef _Trial = ({double w, double floor, Size size, Size rect, double scale});

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
