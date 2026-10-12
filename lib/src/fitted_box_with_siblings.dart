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
/// Text in the box can wrap where that shows the box larger: see
/// [WrapToFit].
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

/// A widget that lays out its child, such as a [Text], no wider than the
/// width that shows the first child (the "box") of the nearest
/// [FittedBoxWithSiblings] above it largest, so the text wraps where that
/// lets the box scale up.
///
/// The box is laid out with no constraints, so without this, a text in it
/// keeps to the lines it has, however long they are, and a long line makes
/// the whole box small.
///
/// The [FittedBoxWithSiblings] picks the width in its layout. It tries
/// widths from the widest line of the unwrapped text down to its longest
/// word, laying out only the [WrapToFit] widgets again for each, and keeps
/// the one that gives the box the largest scale in the rect its
/// [FittedBoxWithSiblings.delegate] returns for the box's size there, so
/// where the siblings go is part of it. Where several widths do equally well,
/// it keeps the widest, and it widens the text into any room the box leaves
/// beside it, so the text wraps at the width another part of the box sets.
/// All the [WrapToFit] widgets in the box wrap at the same width.
///
/// The width is kept while the constraints, the [WrapToFit] widgets in the
/// box and their children, the delegate, the fit, and the box's size stay
/// the same, as when another text in the box changes but keeps its size.
/// Anything else picks it again, which lays out the [WrapToFit] widgets
/// again up to about 25 times, so a room that changes size every frame, as
/// in an animation, picks it every frame.
///
/// Give a [Text] child [TextWidthBasis.longestLine], so it is as wide as its
/// widest line, which lets the search skip the widths that give the same
/// lines.
///
/// The text doesn't wrap, and this lays out its child as is, when it's in a
/// sibling instead of the box, when the [FittedBoxWithSiblings.fit] is
/// anything but [BoxFit.contain] or [BoxFit.scaleDown], or when the
/// [FittedBoxWithSiblings] has unbounded constraints. A dry layout, which
/// can't try widths, uses the width the last layout picked.
class WrapToFit extends SingleChildRenderObjectWidget {
  /// Creates a widget that lays out its [child] no wider than the width that
  /// shows the box of the nearest [FittedBoxWithSiblings] above it largest.
  const WrapToFit({super.key, super.child});

  @override
  RenderWrapToFit createRenderObject(BuildContext context) => RenderWrapToFit();
}
