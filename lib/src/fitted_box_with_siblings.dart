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
  /// always laid out unconstrained, like the child of a [FittedBox].
  final StackFit stackFit;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

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
      );
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
