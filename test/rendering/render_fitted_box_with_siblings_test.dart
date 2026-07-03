import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_rects_delegate.dart';
import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('RenderFittedBoxWithSiblings handles applying paint transform and '
      'hit-testing with empty size', () {
    final fittedBox = RenderFittedBoxWithSiblings(
      delegate: TestRectsDelegate(
        (constraints, boxSize) => [
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
      ),
      children: <RenderBox>[
        RenderCustomPaint(painter: TestCallbackPainter(onPaint: () {})),
      ],
    );

    layout(fittedBox, phase: EnginePhase.flushSemantics);
    final transform = Matrix4.identity();
    fittedBox.applyPaintTransform(fittedBox.firstChild!, transform);
    expect(transform, Matrix4.zero());

    final hitTestResult = BoxHitTestResult();
    expect(
      fittedBox.hitTestChildren(hitTestResult, position: Offset.zero),
      isFalse,
    );
  });

  test('RenderFittedBoxWithSiblings does not paint with empty sizes', () {
    bool painted;
    RenderFittedBoxWithSiblings makeFittedBox(Size size) {
      return RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          ],
        ),
        children: <RenderBox>[
          RenderCustomPaint(
            preferredSize: size,
            painter: TestCallbackPainter(
              onPaint: () {
                painted = true;
              },
            ),
          ),
        ],
      );
    }

    // The RenderFittedBoxWithSiblings paints if both its size and its child's
    // size are nonempty.
    painted = false;
    layout(makeFittedBox(const Size(1, 1)), phase: EnginePhase.paint);
    expect(painted, equals(true));

    // The RenderFittedBoxWithSiblings should not paint if its child is
    // empty-sized.
    painted = false;
    layout(makeFittedBox(Size.zero), phase: EnginePhase.paint);
    expect(painted, equals(false));

    // The RenderFittedBoxWithSiblings should not paint if it is empty.
    painted = false;
    layout(
      makeFittedBox(const Size(1, 1)),
      constraints: BoxConstraints.tight(Size.zero),
      phase: EnginePhase.paint,
    );
    expect(painted, equals(false));
  });

  test('RenderFittedBoxWithSiblings dry layout throws when computeRects '
      'returns too few rects', () {
    final fittedBox = RenderFittedBoxWithSiblings(
      delegate: TestRectsDelegate(
        (constraints, boxSize) => [
          // 1 rect, but 2 children.
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
      ),
      children: <RenderBox>[
        RenderCustomPaint(painter: TestCallbackPainter(onPaint: () {})),
        RenderCustomPaint(painter: TestCallbackPainter(onPaint: () {})),
      ],
    );

    // Dry layout must report the rect count mismatch just like real layout,
    // rather than silently sizing the extra sibling at zero.
    expect(
      () => fittedBox.getDryLayout(BoxConstraints.tight(const Size(200, 200))),
      throwsFlutterError,
    );
  });

  test('RenderFittedBoxWithSiblings dry baseline matches actual baseline', () {
    // The first child (100x50) has no baseline. The sibling reports a
    // baseline 10.0 below its top and is placed at a rect whose top (30.0)
    // differs from where Stack-style alignment would put it, so a dry
    // baseline computed with Stack logic will not match the actual baseline.
    final fittedBox = RenderFittedBoxWithSiblings(
      delegate: TestRectsDelegate(
        (constraints, boxSize) => [
          const Rect.fromLTWH(0, 0, 100, 100),
          const Rect.fromLTWH(20, 30, 50, 20),
        ],
      ),
      children: <RenderBox>[
        RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tight(const Size(100, 50)),
        ),
        _FixedBaselineBox(),
      ],
    );

    final probe = _BaselineProbe(TextBaseline.alphabetic, fittedBox);
    layout(probe, constraints: BoxConstraints.tight(const Size(100, 100)));

    // The sibling's rect top is 30.0 and its baseline is 10.0 below that.
    expect(probe.actualBaseline, equals(40.0));
    expect(probe.dryBaseline, equals(probe.actualBaseline));
  });

  void testFittedBoxWithClipRectLayer() {
    _testLayerReuse<ClipRectLayer>(
      RenderFittedBoxWithSiblings(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          ],
        ),
        children: <RenderBox>[
          // Inject opacity under the clip to force compositing.
          RenderRepaintBoundary(
            child: RenderSizedBox(const Size(100.0, 200.0)),
          ),
        ], // size doesn't matter
      ),
    );
  }

  void testFittedBoxWithTransformLayer() {
    _testLayerReuse<TransformLayer>(
      RenderFittedBoxWithSiblings(
        fit: BoxFit.fill,
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          ],
        ),
        children: <RenderBox>[
          // Inject opacity under the clip to force compositing.
          RenderRepaintBoundary(child: RenderSizedBox(const Size(1, 1))),
        ], // size doesn't matter
      ),
    );
  }

  test(
    'RenderFittedBoxWithSiblings reuses ClipRectLayer',
    testFittedBoxWithClipRectLayer,
  );

  test(
    'RenderFittedBoxWithSiblings reuses TransformLayer',
    testFittedBoxWithTransformLayer,
  );

  test('RenderFittedBoxWithSiblings switches between ClipRectLayer and '
      'TransformLayer, and reuses them', () {
    testFittedBoxWithClipRectLayer();

    // clip -> transform
    testFittedBoxWithTransformLayer();
    // transform -> clip
    testFittedBoxWithClipRectLayer();
  });

  test('RenderFittedBoxWithSiblings respects clipBehavior', () {
    const viewport = BoxConstraints(maxHeight: 100.0, maxWidth: 100.0);
    for (final clip in <Clip?>[null, ...Clip.values]) {
      final context = TestClipPaintingContext();
      final RenderFittedBoxWithSiblings box;
      switch (clip) {
        case Clip.none:
        case Clip.hardEdge:
        case Clip.antiAlias:
        case Clip.antiAliasWithSaveLayer:
          box = RenderFittedBoxWithSiblings(
            delegate: TestRectsDelegate(
              (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
            ),
            children: <RenderBox>[box200x200],
            fit: BoxFit.none,
            clipBehavior: clip!,
          );
        case null:
          box = RenderFittedBoxWithSiblings(
            delegate: TestRectsDelegate(
              (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
            ),
            children: <RenderBox>[box200x200],
            fit: BoxFit.none,
          );
      }
      layout(
        box,
        constraints: viewport,
        phase: EnginePhase.composite,
        onErrors: expectNoFlutterErrors,
      );
      box.paint(context, Offset.zero);
      // By default, clipBehavior should be Clip.none
      expect(context.clipBehavior, equals(clip ?? Clip.none));
    }
  });

  test(
    'RenderFittedBoxWithSiblings can layout with top, right, bottom, left 0.0',
    () {
      final RenderBox size = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      );

      final RenderBox red = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFF0000)),
        child: size,
      );

      final RenderBox green = RenderDecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF00FF00)),
      );

      final RenderBox stack = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate((constraints, boxSize) {
          return [
            const Rect.fromLTWH(0, 0, 100.0, 100.0),
            const Rect.fromLTWH(0, 0, 100.0, 100.0),
          ];
        }),
        textDirection: TextDirection.ltr,
        children: <RenderBox>[red, green],
      );
      // green.parentData! as StackParentData
      //   ..top = 0.0
      //   ..right = 0.0
      //   ..bottom = 0.0
      //   ..left = 0.0;

      layout(stack, constraints: const BoxConstraints());

      expect(stack.size.width, equals(100.0));
      expect(stack.size.height, equals(100.0));

      expect(red.size.width, equals(100.0));
      expect(red.size.height, equals(100.0));

      expect(green.size.width, equals(100.0));
      expect(green.size.height, equals(100.0));
    },
  );

  test('RenderFittedBoxWithSiblings can layout with no children', () {
    final RenderBox stack = RenderFittedBoxWithSiblings(
      delegate: TestRectsDelegate((constraints, boxSize) => []),
      textDirection: TextDirection.ltr,
      children: <RenderBox>[],
    );

    layout(stack, constraints: BoxConstraints.tight(const Size(100.0, 100.0)));

    expect(stack.size.width, equals(100.0));
    expect(stack.size.height, equals(100.0));
  });

  test('RenderFittedBoxWithSiblings in Flex can layout with no children', () {
    // Render an empty Stack in a Flex
    final flex = RenderFlex(
      textDirection: TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <RenderBox>[
        RenderFittedBoxWithSiblings(
          delegate: TestRectsDelegate((_, _) => []),
          textDirection: TextDirection.ltr,
          children: <RenderBox>[],
        ),
      ],
    );

    var stackFlutterErrorThrown = false;
    layout(
      flex,
      constraints: BoxConstraints.tight(const Size(100.0, 100.0)),
      onErrors: () {
        stackFlutterErrorThrown = true;
      },
    );

    expect(stackFlutterErrorThrown, false);
  });

  // More tests in ../widgets/stack_test.dart

  group('Sibling layout', () {
    test('siblings are laid out with tight constraints from rects', () {
      final sibling1 = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );
      final sibling2 = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            const Rect.fromLTWH(0, 0, 200, 150),
            const Rect.fromLTWH(10, 20, 120, 45),
            const Rect.fromLTWH(200, 100, 80, 60),
          ],
        ),
        children: <RenderBox>[
          RenderSizedBox(const Size(100, 50)),
          sibling1,
          sibling2,
        ],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(400, 300)),
      );

      // Siblings should be sized to match their rects.
      expect(sibling1.size, equals(const Size(120, 45)));
      expect(sibling2.size, equals(const Size(80, 60)));
    });

    test('sibling offsets match rect positions', () {
      final sibling1 = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );
      final sibling2 = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(),
      );

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            const Rect.fromLTWH(0, 0, 200, 150),
            const Rect.fromLTWH(10, 20, 120, 45),
            const Rect.fromLTWH(200, 100, 80, 60),
          ],
        ),
        children: <RenderBox>[
          RenderSizedBox(const Size(100, 50)),
          sibling1,
          sibling2,
        ],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(400, 300)),
      );

      final offset1 = (sibling1.parentData! as StackParentData).offset;
      expect(offset1, equals(const Offset(10, 20)));

      final offset2 = (sibling2.parentData! as StackParentData).offset;
      expect(offset2, equals(const Offset(200, 100)));
    });
  });

  group('Paint behavior', () {
    test('all children are painted', () {
      var fittedChildPainted = false;
      var siblingPainted = false;

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            const Rect.fromLTWH(0, 0, 200, 150),
            const Rect.fromLTWH(10, 20, 100, 50),
          ],
        ),
        children: <RenderBox>[
          RenderCustomPaint(
            preferredSize: const Size(100, 50),
            painter: TestCallbackPainter(
              onPaint: () => fittedChildPainted = true,
            ),
          ),
          RenderCustomPaint(
            painter: TestCallbackPainter(onPaint: () => siblingPainted = true),
          ),
        ],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(400, 300)),
        phase: EnginePhase.paint,
      );

      expect(fittedChildPainted, isTrue);
      expect(siblingPainted, isTrue);
    });

    test('siblings paint when fitted child has empty size (issue #5)', () {
      var siblingPainted = false;

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
            const Rect.fromLTWH(10, 10, 100, 50),
          ],
        ),
        children: <RenderBox>[
          // First child with empty preferred size.
          RenderCustomPaint(
            preferredSize: Size.zero,
            painter: TestCallbackPainter(onPaint: () {}),
          ),
          RenderCustomPaint(
            painter: TestCallbackPainter(onPaint: () => siblingPainted = true),
          ),
        ],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(400, 300)),
        phase: EnginePhase.paint,
      );

      // This test exposes issue #5: paint() returns early when
      // firstChild.size.isEmpty, skipping siblings.
      expect(siblingPainted, isTrue);
    });
  });

  group('Hit testing', () {
    test('hit test finds sibling at its rect position', () {
      final sibling = RenderSizedBox(const Size(100, 50));

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            const Rect.fromLTWH(0, 0, 200, 150),
            const Rect.fromLTWH(10, 20, 100, 50),
          ],
        ),
        children: <RenderBox>[RenderSizedBox(const Size(100, 50)), sibling],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(400, 300)),
        phase: EnginePhase.composite,
        onErrors: expectNoFlutterErrors,
      );

      final result = BoxHitTestResult();
      // Hit at center of sibling rect: (10+50, 20+25) = (60, 45).
      final hit = fittedBox.hitTestChildren(
        result,
        position: const Offset(60, 45),
      );
      expect(hit, isTrue);
    });

    test('hit test on fitted child applies transform', () {
      final fittedChild = RenderSizedBox(const Size(100, 50));

      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          ],
        ),
        children: <RenderBox>[fittedChild],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(200, 200)),
        phase: EnginePhase.composite,
        onErrors: expectNoFlutterErrors,
      );

      // With contain: 100x50 in 200x200, scale = 2.0.
      // Dest is 200x100 centered at y=50.
      final result = BoxHitTestResult();
      // Hit at center of the widget: (100, 100). This is inside the
      // scaled child (dest y: 50..150).
      final hit = fittedBox.hitTestChildren(
        result,
        position: const Offset(100, 100),
      );
      expect(hit, isTrue);

      // Hit outside the scaled child (y < 50).
      final result2 = BoxHitTestResult();
      final hit2 = fittedBox.hitTestChildren(
        result2,
        position: const Offset(100, 10),
      );
      expect(hit2, isFalse);
    });
  });

  group('Property setters', () {
    test('setting fit to scaleDown triggers layout', () {
      final fittedBox = RenderFittedBoxWithSiblings(
        fit: BoxFit.contain,
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
          ],
        ),
        children: <RenderBox>[RenderSizedBox(const Size(100, 50))],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(200, 200)),
      );

      // Changing to scaleDown should trigger layout (since scaleDown affects
      // layout).
      fittedBox.fit = BoxFit.scaleDown;
      expect(fittedBox.debugNeedsLayout, isTrue);
    });

    test('setting an equivalent delegate does not trigger layout', () {
      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: const _FullSizeRectsDelegate(),
        children: <RenderBox>[RenderSizedBox(const Size(100, 50))],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(200, 200)),
      );

      // Same instance: no relayout.
      final sameDelegate = fittedBox.delegate;
      fittedBox.delegate = sameDelegate;
      expect(fittedBox.debugNeedsLayout, isFalse);

      // Same runtimeType and shouldRelayout returns false: no relayout.
      fittedBox.delegate = const _FullSizeRectsDelegate();
      expect(fittedBox.debugNeedsLayout, isFalse);
    });

    test('setting a delegate whose shouldRelayout returns true triggers '
        'layout', () {
      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: const _FullSizeRectsDelegate(),
        children: <RenderBox>[RenderSizedBox(const Size(100, 50))],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(200, 200)),
      );

      fittedBox.delegate = const _FullSizeRectsDelegate(relayout: true);
      expect(fittedBox.debugNeedsLayout, isTrue);
    });

    test('setting a delegate of a different type triggers layout', () {
      final fittedBox = RenderFittedBoxWithSiblings(
        delegate: const _FullSizeRectsDelegate(),
        children: <RenderBox>[RenderSizedBox(const Size(100, 50))],
      );

      layout(
        fittedBox,
        constraints: BoxConstraints.tight(const Size(200, 200)),
      );

      // A different runtimeType relayouts even though its shouldRelayout
      // returns false.
      fittedBox.delegate = TestRectsDelegate(
        (constraints, boxSize) => [
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        ],
      );
      expect(fittedBox.debugNeedsLayout, isTrue);
    });
  });
}

// A delegate that returns a single full-size rect and reports [relayout]
// from shouldRelayout.
class _FullSizeRectsDelegate extends FittedBoxWithSiblingsDelegate {
  const _FullSizeRectsDelegate({this.relayout = false});

  final bool relayout;

  @override
  List<Rect> computeRects(BoxConstraints constraints, Size boxSize) => [
    Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
  ];

  @override
  bool shouldRelayout(_FullSizeRectsDelegate oldDelegate) => relayout;
}

// A box that sizes to its constraints and reports a fixed baseline 10.0
// below its top edge.
class _FixedBaselineBox extends RenderBox {
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.smallest;

  @override
  void performLayout() {
    size = constraints.smallest;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => 10.0;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => 10.0;
}

// A proxy that records its child's dry and actual baselines during layout,
// where both queries are legal.
class _BaselineProbe extends RenderProxyBox {
  _BaselineProbe(this.baseline, RenderBox child) : super(child);

  final TextBaseline baseline;
  double? dryBaseline;
  double? actualBaseline;

  @override
  void performLayout() {
    dryBaseline = child!.getDryBaseline(constraints, baseline);
    child!.layout(constraints, parentUsesSize: true);
    size = child!.size;
    actualBaseline = child!.getDistanceToBaseline(baseline, onlyReal: true);
  }
}

// Forces two frames and checks that:
// - a layer is created on the first frame
// - the layer is reused on the second frame
void _testLayerReuse<L extends Layer>(RenderBox renderObject) {
  expect(L, isNot(Layer));
  expect(renderObject.debugLayer, null);
  layout(
    renderObject,
    phase: EnginePhase.paint,
    constraints: BoxConstraints.tight(const Size(10, 10)),
  );
  final Layer? layer = renderObject.debugLayer;
  expect(layer, isA<L>());
  expect(layer, isNotNull);

  // Mark for repaint otherwise pumpFrame is a noop.
  renderObject.markNeedsPaint();
  expect(renderObject.debugNeedsPaint, true);
  pumpFrame(phase: EnginePhase.paint);
  expect(renderObject.debugNeedsPaint, false);
  expect(renderObject.debugLayer, same(layer));
}
