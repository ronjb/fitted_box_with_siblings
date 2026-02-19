// Standard test style: explicit types in closures and non-const children lists.
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-child layout and positioning', () {
    testWidgets('siblings are positioned at their computed rects', (
      WidgetTester tester,
    ) async {
      // 3 children: fitted child (100x50) + 2 siblings.
      // Parent is 400x300.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                const Rect.fromLTWH(0, 0, 400, 300),
                const Rect.fromLTWH(10, 20, 100, 40),
                const Rect.fromLTWH(200, 150, 80, 60),
              ],
              children: [
                const SizedBox(width: 100, height: 50),
                Container(color: Colors.red),
                Container(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);

      // Second child (first sibling) should be at rect (10, 20, 100, 40).
      final redBox = tester.firstRenderObject<RenderBox>(
        find.byType(Container).at(0),
      );
      final redTopLeft = redBox.localToGlobal(Offset.zero);
      expect(redTopLeft, equals(parentTopLeft + const Offset(10, 20)));

      // Third child (second sibling) should be at rect (200, 150, 80, 60).
      final blueBox = tester.firstRenderObject<RenderBox>(
        find.byType(Container).at(1),
      );
      final blueTopLeft = blueBox.localToGlobal(Offset.zero);
      expect(blueTopLeft, equals(parentTopLeft + const Offset(200, 150)));
    });

    testWidgets('siblings are sized to their rect size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                const Rect.fromLTWH(0, 0, 400, 300),
                const Rect.fromLTWH(10, 20, 120, 45),
                const Rect.fromLTWH(200, 150, 80, 60),
              ],
              children: [
                const SizedBox(width: 100, height: 50),
                Container(color: Colors.red),
                Container(color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      final redBox = tester.firstRenderObject<RenderBox>(
        find.byType(Container).at(0),
      );
      expect(redBox.size, equals(const Size(120, 45)));

      final blueBox = tester.firstRenderObject<RenderBox>(
        find.byType(Container).at(1),
      );
      expect(blueBox.size, equals(const Size(80, 60)));
    });

    testWidgets('fitted child is scaled according to BoxFit.contain', (
      WidgetTester tester,
    ) async {
      final Key insideKey = UniqueKey();

      // Container 200x200, child 100x50.
      // BoxFit.contain: scale = min(200/100, 200/50) = 2.0
      // Destination: 200x100, centered vertically at (0, 50).
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final insideBox = tester.firstRenderObject<RenderBox>(
        find.byKey(insideKey),
      );
      // Child is 100x50. With contain in 200x200, scale is 2x.
      // Bottom-right of child (100,50) maps to (200, 150) in parent local.
      // But parent is centered on 800x600 screen, so parent top-left is
      // (300, 200). Destination rect top is 50 (centered), so child (100,50)
      // maps to parent (200, 50+100) = parent(200, 150).
      final insideBottomRight = insideBox.localToGlobal(const Offset(100, 50));
      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentBottomRight = parentBox.localToGlobal(const Offset(200, 150));
      expect(insideBottomRight, equals(parentBottomRight));
    });

    testWidgets('fitted child is scaled according to BoxFit.fill', (
      WidgetTester tester,
    ) async {
      final Key insideKey = UniqueKey();

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              fit: BoxFit.fill,
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final insideBox = tester.firstRenderObject<RenderBox>(
        find.byKey(insideKey),
      );
      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );

      // BoxFit.fill: child fills entire rect. (100,50) -> (200,200).
      final insideBottomRight = insideBox.localToGlobal(const Offset(100, 50));
      final parentBottomRight = parentBox.localToGlobal(const Offset(200, 200));
      expect(insideBottomRight, equals(parentBottomRight));

      // Top-left should also match.
      final insideTopLeft = insideBox.localToGlobal(Offset.zero);
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);
      expect(insideTopLeft, equals(parentTopLeft));
    });
  });

  group('Hit testing', () {
    testWidgets('tap on a sibling registers', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                const Rect.fromLTWH(0, 0, 200, 150),
                const Rect.fromLTWH(200, 0, 200, 150),
              ],
              children: [
                const SizedBox(width: 100, height: 50),
                GestureDetector(
                  onTap: () => tapped = true,
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap in the center of the sibling rect.
      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);
      // Sibling is at (200, 0) with size (200, 150). Center is (300, 75).
      await tester.tapAt(parentTopLeft + const Offset(300, 75));
      expect(tapped, isTrue);
    });

    testWidgets('tap on the fitted child registers', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped = true,
                  child: const SizedBox(width: 100, height: 50),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap in the center of the parent (which contains the scaled child).
      await tester.tap(find.byType(FittedBoxWithSiblings));
      expect(tapped, isTrue);
    });

    testWidgets('siblings occlude in correct z-order (last child wins)', (
      WidgetTester tester,
    ) async {
      String? lastTapped;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                const Rect.fromLTWH(0, 0, 200, 150),
                // Overlapping rects for siblings.
                const Rect.fromLTWH(100, 50, 200, 150),
                const Rect.fromLTWH(100, 50, 200, 150),
              ],
              children: [
                const SizedBox(width: 100, height: 50),
                GestureDetector(
                  onTap: () => lastTapped = 'first_sibling',
                  child: Container(color: Colors.red),
                ),
                GestureDetector(
                  onTap: () => lastTapped = 'second_sibling',
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap in the overlap area. The last child (second sibling) should win.
      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);
      await tester.tapAt(parentTopLeft + const Offset(200, 125));
      expect(lastTapped, equals('second_sibling'));
    });
  });

  group('Issue #5 - siblings with empty fitted child', () {
    testWidgets('siblings paint when fitted child has empty size', (
      WidgetTester tester,
    ) async {
      // First child is SizedBox.shrink() (empty size), but siblings have
      // valid rects and should still be painted.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
                const Rect.fromLTWH(10, 10, 100, 50),
              ],
              children: [
                const SizedBox.shrink(),
                Container(color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // The sibling Container should still be findable and painted.
      expect(find.byType(Container), findsOneWidget);
      final redBox = tester.firstRenderObject<RenderBox>(
        find.byType(Container),
      );
      // If issue #5 is present, the sibling won't be painted because paint()
      // returns early when firstChild.size.isEmpty.
      expect(redBox.size, equals(const Size(100, 50)));

      // Verify the sibling is actually visible by checking it can be found
      // at its expected position.
      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);
      final hitResult = tester.hitTestOnBinding(
        parentTopLeft + const Offset(60, 35),
      );
      // The sibling should be hit-testable at its position.
      final renderObjects = hitResult.path
          .whereType<BoxHitTestEntry>()
          .map((e) => e.target)
          .toList();
      expect(renderObjects, contains(redBox));
    });

    testWidgets('siblings receive taps when fitted child has empty size', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
                const Rect.fromLTWH(10, 10, 100, 50),
              ],
              children: [
                const SizedBox.shrink(),
                GestureDetector(
                  onTap: () => tapped = true,
                  child: Container(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      final parentTopLeft = parentBox.localToGlobal(Offset.zero);
      await tester.tapAt(parentTopLeft + const Offset(60, 35));
      expect(tapped, isTrue);
    });
  });

  group('Edge cases', () {
    testWidgets('single child (no siblings) works like FittedBox', (
      WidgetTester tester,
    ) async {
      final Key insideKey = UniqueKey();

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final parentBox = tester.firstRenderObject<RenderBox>(
        find.byType(FittedBoxWithSiblings),
      );
      expect(parentBox.size, equals(const Size(200, 200)));

      final insideBox = tester.firstRenderObject<RenderBox>(
        find.byKey(insideKey),
      );
      expect(insideBox.size, equals(const Size(100, 50)));

      // Contain: scale = min(200/100, 200/50) = 2.0
      // Destination 200x100 centered at y=50.
      final insidePoint = insideBox.localToGlobal(const Offset(100, 50));
      final parentPoint = parentBox.localToGlobal(const Offset(200, 150));
      expect(insidePoint, equals(parentPoint));
    });

    testWidgets('computeRects error: wrong number of rects', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                // Only 1 rect, but 2 children.
                const Rect.fromLTWH(0, 0, 200, 200),
              ],
              children: [
                const SizedBox(width: 100, height: 50),
                Container(color: Colors.red),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('computeRects error: non-finite rects', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                const Rect.fromLTWH(0, 0, double.nan, 200),
              ],
              children: [const SizedBox(width: 100, height: 50)],
            ),
          ),
        ),
      );

      // The non-finite rect causes a FlutterError in performLayout, which
      // cascades into multiple exceptions as the framework tries to continue.
      expect(tester.takeException(), isNotNull);
    });
  });

  group('Property updates', () {
    testWidgets('changing fit triggers repaint', (WidgetTester tester) async {
      final Key insideKey = UniqueKey();

      // Start with BoxFit.contain.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final insideBox = tester.firstRenderObject<RenderBox>(
        find.byKey(insideKey),
      );
      final containBottomRight = insideBox.localToGlobal(const Offset(100, 50));

      // Switch to BoxFit.fill.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              fit: BoxFit.fill,
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final fillBottomRight = insideBox.localToGlobal(const Offset(100, 50));

      // The transform should differ between contain and fill.
      expect(fillBottomRight, isNot(equals(containBottomRight)));
    });

    testWidgets('changing alignment updates positioning', (
      WidgetTester tester,
    ) async {
      final Key insideKey = UniqueKey();

      // Start with Alignment.center.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              alignment: Alignment.center,
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final insideBox = tester.firstRenderObject<RenderBox>(
        find.byKey(insideKey),
      );
      final centerTopLeft = insideBox.localToGlobal(Offset.zero);

      // Switch to Alignment.topLeft.
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              alignment: Alignment.topLeft,
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [SizedBox(key: insideKey, width: 100, height: 50)],
            ),
          ),
        ),
      );

      final topLeftTopLeft = insideBox.localToGlobal(Offset.zero);

      // With contain (100x50 in 200x200, scale 2x -> dest 200x100):
      //   center alignment -> child at y=50
      //   topLeft alignment -> child at y=0
      expect(topLeftTopLeft, isNot(equals(centerTopLeft)));
    });

    testWidgets('changing clipBehavior works', (WidgetTester tester) async {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [const SizedBox(width: 100, height: 50)],
            ),
          ),
        ),
      );

      final renderObject = tester
          .firstRenderObject<RenderFittedBoxWithSiblings>(
            find.byType(FittedBoxWithSiblings),
          );
      expect(renderObject.clipBehavior, equals(Clip.none));

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: FittedBoxWithSiblings(
              clipBehavior: Clip.hardEdge,
              computeRects: (constraints, boxSize) => [
                Rect.fromLTWH(
                  0,
                  0,
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              ],
              children: [const SizedBox(width: 100, height: 50)],
            ),
          ),
        ),
      );

      expect(renderObject.clipBehavior, equals(Clip.hardEdge));
    });
  });
}
