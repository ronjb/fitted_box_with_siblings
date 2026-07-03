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
    required FittedBoxWithSiblingsDelegate delegate,
  }) : _fit = fit,
       _alignment = alignment,
       _textDirection = textDirection,
       _stackFit = stackFit,
       _clipBehavior = clipBehavior,
       _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData) {
      child.parentData = StackParentData();
    }
  }

  bool _fitAffectsLayout(BoxFit fit) {
    switch (fit) {
      case BoxFit.scaleDown:
        return true;
      case BoxFit.contain:
      case BoxFit.cover:
      case BoxFit.fill:
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
      case BoxFit.none:
        return false;
    }
  }

  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    if (_fit == value) {
      return;
    }
    final lastFit = _fit;
    _fit = value;
    if (_fitAffectsLayout(lastFit) || _fitAffectsLayout(value)) {
      markNeedsLayout();
    } else {
      _clearPaintData();
      markNeedsPaint();
    }
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
    return defaultComputeDistanceToHighestActualBaseline(baseline);
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

    final alignment = _resolvedAlignment;
    var baselineOffset = BaselineOffset.noBaseline;
    var i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      // Mirror the constraints and offset that performLayout applies: the
      // first child is laid out unconstrained, and siblings are laid out
      // with constraints tight to their rect. For siblings the alongOffset
      // term is always zero since their size equals the rect size. In
      // release mode a missing rect falls back to Rect.zero, matching
      // performLayout.
      final rect = i < result.rects.length ? result.rects[i] : Rect.zero;
      final childConstraints = i == 0
          ? const BoxConstraints()
          : BoxConstraints.tight(rect.size);
      final childBaseline = child.getDryBaseline(childConstraints, baseline);
      if (childBaseline != null) {
        final y =
            alignment
                .alongOffset(
                  rect.size - child.getDryLayout(childConstraints) as Offset,
                )
                .dy +
            rect.top;
        baselineOffset = baselineOffset.minOf(
          BaselineOffset(childBaseline + y),
        );
      }
      i++;
    }
    return baselineOffset.offset;
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
    );
    size = result.size;
    _rects = result.rects;

    // Validate after size is set, so a rect count mismatch surfaces as a
    // single descriptive error instead of cascading missing-size exceptions.
    _checkRectCount(_rects);

    final resolvedAlignment = _resolvedAlignment;
    var child = firstChild;
    var i = 0;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (childParentData.isPositioned) {
        throw UnimplementedError(
          'Positioned children are not supported in FittedBoxWithSiblings.',
        );
      } else {
        // The rect count is validated by _checkRectCount above in debug
        // mode; in release mode a missing rect falls back to Rect.zero.
        final rect = i < _rects.length ? _rects[i] : Rect.zero;
        childParentData.offset =
            resolvedAlignment.alongOffset(rect.size - child.size as Offset) +
            Offset(rect.left, rect.top);
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
      i++;
    }

    _clearPaintData();
  }

  ({Size size, List<Rect> rects}) _computeSize({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
  }) {
    if (childCount == 0) {
      return (
        size: constraints.biggest.isFinite
            ? constraints.biggest
            : constraints.smallest,
        rects: [],
      );
    }

    late List<Rect> rects;

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
        final childSize = layoutChild(child, const BoxConstraints());
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
    return (size: size, rects: rects);
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

  bool get _hasEmptyFirstChild =>
      firstChild != null && firstChild!.size.isEmpty;

  void _updatePaintData() {
    if (_transform != null) {
      return;
    }

    // The _rects list is only empty on an error frame, when computeRects
    // returned no rects for a non-zero number of children.
    if (firstChild == null || _hasEmptyFirstChild || _rects.isEmpty) {
      // Siblings are still painted when the first child is empty, so they
      // can still overflow the bounds.
      _hasVisualOverflow = _siblingsOverflowBounds;
      _transform = Matrix4.identity();
    } else {
      final boxRect = _rects[0];
      final resolvedAlignment = _resolvedAlignment;
      final childSize = firstChild!.size;
      final sizes = applyBoxFit(_fit, childSize, boxRect.size);
      final scaleX = sizes.destination.width / sizes.source.width;
      final scaleY = sizes.destination.height / sizes.source.height;
      final sourceRect = resolvedAlignment.inscribe(
        sizes.source,
        Offset.zero & childSize,
      );
      final destinationRect = resolvedAlignment.inscribe(
        sizes.destination,
        boxRect,
      );
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
    final skipFirstChild = _hasEmptyFirstChild;
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

    final skipFirstChild = _hasEmptyFirstChild;
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
      return !child.size.isEmpty;
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
      );
  }
}

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
