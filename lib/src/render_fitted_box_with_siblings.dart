/// RenderFittedBoxWithSiblings
/// @docImport 'fitted_box_with_siblings.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Signature for a function that given the [constraints] and [boxSize],
/// returns the rects for the fitted box and its siblings.
typedef RectsForFittedBoxWithSiblings =
    List<Rect> Function(BoxConstraints constraints, Size boxSize);

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
    required RectsForFittedBoxWithSiblings computeRects,
  }) : _fit = fit,
       _alignment = alignment,
       _textDirection = textDirection,
       _stackFit = stackFit,
       _clipBehavior = clipBehavior,
       _computeRects = computeRects {
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
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  RectsForFittedBoxWithSiblings get computeRects => _computeRects;
  RectsForFittedBoxWithSiblings _computeRects;
  set computeRects(RectsForFittedBoxWithSiblings value) {
    _computeRects = value;
    _clearPaintData();
    markNeedsLayout();
  }

  static double getIntrinsicDimension(
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
  double computeMinIntrinsicWidth(double height) {
    return getIntrinsicDimension(
      firstChild,
      (child) => child.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return getIntrinsicDimension(
      firstChild,
      (child) => child.getMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return getIntrinsicDimension(
      firstChild,
      (child) => child.getMinIntrinsicHeight(width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return getIntrinsicDimension(
      firstChild,
      (child) => child.getMaxIntrinsicHeight(width),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  static double? _baselineForChild(
    RenderBox child,
    Size stackSize,
    BoxConstraints nonPositionedChildConstraints,
    Alignment alignment,
    TextBaseline baseline,
  ) {
    final childParentData = child.parentData! as StackParentData;
    final childConstraints = childParentData.isPositioned
        ? childParentData.positionedChildConstraints(stackSize)
        : nonPositionedChildConstraints;
    final baselineOffset = child.getDryBaseline(childConstraints, baseline);
    if (baselineOffset == null) {
      return null;
    }
    final y = switch (childParentData) {
      StackParentData(:final double top?) => top,
      StackParentData(:final double bottom?) =>
        stackSize.height - bottom - child.getDryLayout(childConstraints).height,
      StackParentData() =>
        alignment
            .alongOffset(
              stackSize - child.getDryLayout(childConstraints) as Offset,
            )
            .dy,
    };
    return baselineOffset + y;
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final nonPositionedChildConstraints = switch (stackFit) {
      StackFit.loose => constraints.loosen(),
      StackFit.expand => BoxConstraints.tight(constraints.biggest),
      StackFit.passthrough => constraints,
    };

    final alignment = _resolvedAlignment;
    final size = getDryLayout(constraints);

    var baselineOffset = BaselineOffset.noBaseline;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      baselineOffset = baselineOffset.minOf(
        BaselineOffset(
          _baselineForChild(
            child,
            size,
            nonPositionedChildConstraints,
            alignment,
            baseline,
          ),
        ),
      );
    }
    return baselineOffset.offset;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _computeSize(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
    ).size;
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

    final resolvedAlignment = _resolvedAlignment;
    var child = firstChild;
    var i = 0;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      if (childParentData.isPositioned) {
        throw UnimplementedError(
          'Positioned children are not supported in FittedBoxWithSiblings.',
        );
      } else if (i < _rects.length) {
        final rect = _rects[i];
        childParentData.offset =
            resolvedAlignment.alongOffset(rect.size - child.size as Offset) +
            Offset(rect.left, rect.top);
      } else {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'The FittedBoxWithSiblings computeRects function must return a '
            'rect for every child.',
          ),
          ErrorDescription(
            'The number of rects returned by the computeRects function must '
            'match the number of the FittedBoxWithSiblings children.',
          ),
          ErrorHint(
            'The computeRects function returned ${_rects.length} rects, '
            'but there are $childCount children.',
          ),
        ]);
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
        rects = computeRects(nonPositionedConstraints, childSize);

        if (!rects.every((r) => r.isFinite)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('The rects returned by computeRects must be finite.'),
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
      } else {
        final rectSize = i < rects.length ? rects[i].size : Size.zero;
        layoutChild(child, BoxConstraints.tight(rectSize));
      }

      child = childParentData.nextSibling;
      i++;
    }

    final boundingRect = rects.boundingRect;
    final size = constraints.constrain(
      Size(boundingRect.right, boundingRect.bottom),
    );
    assert(size.isFinite);
    return (size: size, rects: rects);
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

    if (firstChild == null || _hasEmptyFirstChild) {
      _hasVisualOverflow = false;
      _transform = Matrix4.identity();
    } else {
      final boxRect = _rects.isNotEmpty ? _rects[0] : Rect.zero;
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
      _hasVisualOverflow =
          sourceRect.width < childSize.width ||
          sourceRect.height < childSize.height;
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
