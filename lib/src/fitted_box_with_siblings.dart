import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'render_fitted_box_with_siblings.dart';

/// A widget which scales and positions the first child (the "box") within
/// itself according to [fit], similar to [FittedBox]. The positioning of the
/// box and its siblings is determined by the [delegate], whose
/// [FittedBoxWithSiblingsDelegate.computeRects] method is given the overall
/// constraints and the size returned by calling `layout` on the first child
/// (the "box"), and must return the rectangles for the box and its siblings.
///
/// The intrinsic dimensions of this widget are approximated from the
/// children's intrinsic dimensions and may not match the size that results
/// from [FittedBoxWithSiblingsDelegate.computeRects], so wrapping this widget
/// in [IntrinsicWidth] or [IntrinsicHeight] is discouraged.
///
/// Unlike [FittedBox], which reports its child's unscaled baseline, this
/// widget reports the box's baseline where it is painted, so a scaled box
/// lines up with its neighbors in a baseline-aligned [Row].
///
/// See also:
///
/// * [FittedBox], which scales and positions its child within itself according
///   to [fit] and [alignment].
/// * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FittedBoxWithSiblings extends MultiChildRenderObjectWidget {
  /// Creates a widget which scales and positions the first child (the "box")
  /// within itself according to [fit], similar to [FittedBox]. The positioning
  /// of the box and its siblings is determined by the [delegate], whose
  /// [FittedBoxWithSiblingsDelegate.computeRects] method is given the overall
  /// constraints and the size returned by calling `layout` on the first child
  /// (the "box"), and must return the rectangles for the box and its siblings.
  const FittedBoxWithSiblings({
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.textDirection,
    this.stackFit = StackFit.loose,
    this.clipBehavior = Clip.none,
    this.expandBox,
    required this.delegate,
    super.children,
  });

  /// How to inscribe the first child into the space allocated during layout.
  final BoxFit fit;

  /// How to align the first child (the "box") within the bounds alloted to it.
  ///
  /// An alignment of (-1.0, -1.0) aligns the child to the top-left corner of
  /// the bounds. An alignment of (1.0, 0.0) aligns the child to the middle
  /// of the right edge of the bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// How to transform the constraints passed to the [delegate]'s
  /// [FittedBoxWithSiblingsDelegate.computeRects] method.
  ///
  /// The constraints passed into the [FittedBoxWithSiblings] from its parent
  /// are either loosened ([StackFit.loose]), tightened to their biggest size
  /// ([StackFit.expand]), or passed through unmodified
  /// ([StackFit.passthrough]) before being given to
  /// [FittedBoxWithSiblingsDelegate.computeRects].
  ///
  /// This does not affect how the first child (the "box") is laid out — it is
  /// laid out unconstrained, like the child of a [FittedBox], and then grown
  /// along [expandBox] when that is set.
  final StackFit stackFit;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The axis along which the first child (the "box") grows to fill its
  /// rect, or null to keep it at its own size.
  ///
  /// The box is always laid out unconstrained first, and that size is what
  /// the [delegate] is given. When [expandBox] is set, the box is then laid
  /// out again with its extent across this axis at most its own, and its
  /// extent along this axis fixed to the extent that fills the rect the
  /// [delegate] returned for it, at the scale [fit] applies to the box's own
  /// size, when that is larger than the box's own extent. A box that can
  /// grow, such as a [Column] with [MainAxisSize.max], then fills its rect
  /// instead of leaving space beside it, at the same scale. The rects are not
  /// recomputed.
  ///
  /// This has no effect when [fit] already fills the rect along this axis,
  /// such as [BoxFit.cover] and [BoxFit.fill].
  ///
  /// Defaults to null.
  final Axis? expandBox;

  /// The delegate that computes the rectangles for the box and its siblings.
  ///
  /// Its [FittedBoxWithSiblingsDelegate.computeRects] method is given the
  /// overall constraints and the size returned by calling `layout` on the
  /// first child (the "box"), and must return the rectangles for the box and
  /// its siblings.
  final FittedBoxWithSiblingsDelegate delegate;

  @override
  RenderFittedBoxWithSiblings createRenderObject(BuildContext context) {
    assert(_debugCheckHasDirectionality(context));
    return RenderFittedBoxWithSiblings(
      fit: fit,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      stackFit: stackFit,
      clipBehavior: clipBehavior,
      expandBox: expandBox,
      delegate: delegate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFittedBoxWithSiblings renderObject,
  ) {
    assert(_debugCheckHasDirectionality(context));
    renderObject
      ..fit = fit
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..stackFit = stackFit
      ..clipBehavior = clipBehavior
      ..expandBox = expandBox
      ..delegate = delegate;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<BoxFit>('fit', fit))
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      )
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

  bool _debugCheckHasDirectionality(BuildContext context) {
    if (alignment is AlignmentDirectional && textDirection == null) {
      assert(
        debugCheckHasDirectionality(
          context,
          why: "to resolve the 'alignment' argument",
          hint: alignment == AlignmentDirectional.topStart
              ? "The default value for 'alignment' is "
                    'AlignmentDirectional.topStart, which requires a text '
                    'direction.'
              : null,
          alternative:
              'Instead of providing a Directionality widget, another solution '
              "would be passing a non-directional 'alignment', or an explicit "
              "'textDirection', to the $runtimeType.",
        ),
      );
    }
    return true;
  }
}
