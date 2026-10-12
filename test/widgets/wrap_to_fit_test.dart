// Standard test style: explicit types in closures.
// ignore_for_file: avoid_types_on_closure_parameters

import 'dart:math' as math;

import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_rects_delegate.dart';

// Ten four-letter words. The test font's glyphs, the space too, are as wide
// as the font size, so at 10 these are 490x10 on one line, and k words on a
// line are (5k - 1) * 10 wide.
const _words = 'aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa';

// Words of different lengths, 650 wide on one line, the longest 70.
const _someWords =
    'aaaa bb cccccc d eeeee ffff gg hhhhhhh i jjjj kkkkk ll mmm nnnnnn';

const _textKey = Key('text');
const _boxKey = Key('box');

void main() {
  testWidgets('wraps where the box fills its rect best', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        box: WrapToFit(key: _boxKey, child: _text(_words)),
      ),
    );

    // Two words a line, 90x50, fills the 200x100 room at a scale of 2. One
    // word a line, 40x100, gets 1, three, 140x40, gets 1.43, and one line,
    // 490x10, gets 0.41.
    expect(_sizeOf(tester, _textKey), const Size(90, 50));
    expect(_scaleOf(tester), 2);
  });

  testWidgets("doesn't wrap where the box's height limits it", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _build(
        room: const Size(600, 10),
        box: WrapToFit(key: _boxKey, child: _text(_words)),
      ),
    );

    expect(_sizeOf(tester, _textKey), const Size(490, 10));
    expect(
      tester.renderObject<RenderBox>(find.byKey(_textKey)).constraints.maxWidth,
      double.infinity,
    );
  });

  testWidgets('picks the widest width of those that do equally well, and '
      'widens into the room the box leaves', (WidgetTester tester) async {
    await tester.pumpWidget(
      _build(
        room: const Size(300, 100),
        box: Column(
          key: _boxKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 300, height: 10),
            WrapToFit(child: _text(_words)),
          ],
        ),
      ),
    );

    // The 300 wide row sets the box's width, so two to six words a line all
    // fit the box at a scale of 1. Six words a line is the widest.
    expect(_sizeOf(tester, _textKey), const Size(290, 20));
    expect(_scaleOf(tester), 1);
  });

  testWidgets('wraps all the WrapToFit widgets in the box at the same width', (
    WidgetTester tester,
  ) async {
    const otherKey = Key('other');
    await tester.pumpWidget(
      _build(
        room: const Size(300, 200),
        box: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WrapToFit(child: _text(_words)),
            WrapToFit(child: _text(_someWords, key: otherKey)),
          ],
        ),
      ),
    );

    double wrapWidthOf(Key key) =>
        tester.renderObject<RenderBox>(find.byKey(key)).constraints.maxWidth;
    expect(wrapWidthOf(_textKey), lessThan(490));
    expect(wrapWidthOf(otherKey), wrapWidthOf(_textKey));
  });

  group('matches a scan of every width', () {
    // A sibling 100 wide beside a box narrower than the room, or 100 high
    // below a wider one.
    List<Rect> besideOrBelow(BoxConstraints constraints, Size boxSize) {
      final room = constraints.biggest;
      return boxSize.width / boxSize.height > room.width / room.height
          ? [
              Rect.fromLTWH(0, 0, room.width, room.height - 100),
              Rect.fromLTWH(0, room.height - 100, room.width, 100),
            ]
          : [
              Rect.fromLTWH(0, 0, room.width - 100, room.height),
              Rect.fromLTWH(room.width - 100, 0, 100, room.height),
            ];
    }

    // A sibling below a box more than three times as wide as it is high, or
    // beside any other, so where it goes doesn't switch where the box takes
    // the room's shape.
    List<Rect> belowOnlyAWideBox(BoxConstraints constraints, Size boxSize) {
      final room = constraints.biggest;
      return boxSize.width / boxSize.height > 3
          ? [
              Rect.fromLTWH(0, 0, room.width, 130),
              Rect.fromLTWH(0, 130, room.width, room.height - 130),
            ]
          : [
              Rect.fromLTWH(0, 0, 150, room.height),
              Rect.fromLTWH(150, 0, room.width - 150, room.height),
            ];
    }

    // A small rect beside a box up to 0.8 times as wide as it is high, and a
    // much larger one, of a shape only 13% wider, beside a wider box. With
    // this text, the search asks about shapes 15% apart.
    List<Rect> aLittleWiderRect(BoxConstraints constraints, Size boxSize) =>
        boxSize.width / boxSize.height > 0.8
        ? const [Rect.fromLTWH(0, 0, 340, 400), Rect.fromLTWH(340, 0, 60, 400)]
        : const [Rect.fromLTWH(0, 0, 75, 100), Rect.fromLTWH(75, 0, 325, 400)];

    // A small rect beside a box less than 0.85 times as wide as it is high,
    // and a much larger one beside a wider box, which is wider than that rect
    // from the start.
    List<Rect> aRectNarrowerThanTheBox(
      BoxConstraints constraints,
      Size boxSize,
    ) => boxSize.width / boxSize.height >= 0.85
        ? const [Rect.fromLTWH(0, 0, 320, 400), Rect.fromLTWH(320, 0, 80, 400)]
        : const [Rect.fromLTWH(0, 0, 50, 100), Rect.fromLTWH(50, 0, 350, 400)];

    final cases = [
      (
        name: 'a text alone',
        room: const Size(300, 200),
        box: (Widget text) => text,
        rects: _fill,
        siblings: 0,
      ),
      (
        name: 'a text under a narrower row',
        room: const Size(400, 300),
        box: (Widget text) =>
            Column(children: [const SizedBox(width: 120, height: 30), text]),
        rects: _fill,
        siblings: 0,
      ),
      (
        name: 'siblings that go beside or below the box',
        room: const Size(500, 400),
        box: (Widget text) => text,
        rects: besideOrBelow,
        siblings: 1,
      ),
      (
        name: 'siblings that go below only a much wider box',
        room: const Size(400, 400),
        box: (Widget text) => text,
        rects: belowOnlyAWideBox,
        siblings: 1,
      ),
      (
        name: 'a rect that follows the box',
        room: const Size(400, 400),
        box: (Widget text) => text,
        rects: _followTheBox,
        siblings: 1,
      ),
      (
        name: 'a rect that changes shape by less than the search steps',
        room: const Size(400, 400),
        box: (Widget text) => text,
        rects: aLittleWiderRect,
        siblings: 1,
      ),
      (
        name: 'a box already wider than the rect it changes to',
        room: const Size(400, 400),
        box: (Widget text) => text,
        rects: aRectNarrowerThanTheBox,
        siblings: 1,
      ),
      (
        name: 'tables beside the box, in as many columns as fit',
        room: const Size(1920, 100),
        box: (Widget text) => text,
        rects: _tablesBeside,
        siblings: 1,
      ),
      (
        name: 'a rect that changes at nearly every shape',
        room: const Size(400, 400),
        box: (Widget text) => text,
        rects: _stepsWithTheBox,
        siblings: 1,
      ),
    ];

    for (final c in cases) {
      testWidgets(c.name, (WidgetTester tester) async {
        Widget build(Widget text) => _build(
          room: c.room,
          box: KeyedSubtree(key: _boxKey, child: c.box(text)),
          delegate: TestRectsDelegate(c.rects),
          siblings: [for (var i = 0; i < c.siblings; i++) const SizedBox()],
        );

        await tester.pumpWidget(build(WrapToFit(child: _text(_someWords))));
        final scale = _scaleOf(tester);

        // Every line width is a multiple of 10, from the longest word up to
        // the whole line.
        var best = 0.0;
        for (var width = 70.0; width <= 650; width += 10) {
          await tester.pumpWidget(
            build(
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: _text(_someWords),
              ),
            ),
          );
          if (_scaleOf(tester) > best) best = _scaleOf(tester);
        }

        expect(scale, greaterThanOrEqualTo(best * 0.995));
      });
    }
  });

  testWidgets('asks the delegate about at most 150 shapes, with a rect that '
      'follows the box', (WidgetTester tester) async {
    // Tighter than the 200 the docs allow, since the rect changes only where
    // its height stops following the box.
    final boxSizes = <Size>[];
    await tester.pumpWidget(
      _build(
        room: const Size(400, 400),
        delegate: TestRectsDelegate((constraints, boxSize) {
          boxSizes.add(boxSize);
          return _followTheBox(constraints, boxSize);
        }),
        box: WrapToFit(child: _text(_someWords)),
        siblings: [const SizedBox()],
      ),
    );

    // The test font makes every size a layout gives whole, so the others are
    // the shapes the search asks about with no layout.
    bool isWhole(double x) => x == x.roundToDouble();
    final shapes = boxSizes.where(
      (size) => !isWhole(size.width) || !isWhole(size.height),
    );
    expect(shapes.length, lessThanOrEqualTo(150));
  });

  testWidgets('asks the delegate about at most 200 shapes, with tables beside '
      'the box', (WidgetTester tester) async {
    // The tables' columns, and so the box's rect, change between most of the
    // shapes the search asks about.
    final boxSizes = <Size>[];
    await tester.pumpWidget(
      _build(
        room: const Size(1920, 100),
        delegate: TestRectsDelegate((constraints, boxSize) {
          boxSizes.add(boxSize);
          return _tablesBeside(constraints, boxSize);
        }),
        box: WrapToFit(child: _text(_someWords)),
        siblings: [const SizedBox()],
      ),
    );

    // The test font makes every size a layout gives whole, so the others are
    // the shapes the search asks about with no layout.
    bool isWhole(double x) => x == x.roundToDouble();
    final shapes = boxSizes.where(
      (size) => !isWhole(size.width) || !isWhole(size.height),
    );
    expect(shapes.length, lessThanOrEqualTo(200));
  });

  testWidgets('tries at most 25 widths, and asks the delegate about at most '
      '400 shapes, with a rect that changes at nearly every shape', (
    WidgetTester tester,
  ) async {
    final boxSizes = <Size>[];
    await tester.pumpWidget(
      _build(
        room: const Size(400, 400),
        delegate: TestRectsDelegate((constraints, boxSize) {
          boxSizes.add(boxSize);
          return _stepsWithTheBox(constraints, boxSize);
        }),
        box: WrapToFit(child: _text(_someWords)),
        siblings: [const SizedBox()],
      ),
    );

    // The test font makes every size a layout gives whole, so these are one
    // for each width tried, and one for the rects of the last layout. The
    // others are the shapes the search asks about with no layout.
    bool isWhole(double x) => x == x.roundToDouble();
    final laidOut = boxSizes.where(
      (size) => isWhole(size.width) && isWhole(size.height),
    );
    expect(laidOut.length - 1, lessThanOrEqualTo(25));
    expect(boxSizes.length - laidOut.length, lessThanOrEqualTo(400));
  });

  testWidgets('with BoxFit.scaleDown, wraps only as much as the box needs to '
      'fit unscaled', (WidgetTester tester) async {
    await tester.pumpWidget(
      _build(
        room: const Size(250, 200),
        fit: BoxFit.scaleDown,
        box: WrapToFit(key: _boxKey, child: _text(_someWords)),
      ),
    );

    // Wrapping at 220 to 269 fits the 250 wide room in three lines. Any wider
    // puts ffff on the first line too, which makes it 270 wide.
    expect(_sizeOf(tester, _textKey), const Size(220, 30));
    expect(_scaleOf(tester), 1);
  });

  testWidgets("doesn't wrap with fits other than contain and scaleDown", (
    WidgetTester tester,
  ) async {
    Widget build(BoxFit fit) => _build(
      room: const Size(200, 100),
      fit: fit,
      box: WrapToFit(child: _text(_words)),
    );

    for (final fit in [
      BoxFit.fill,
      BoxFit.cover,
      BoxFit.fitWidth,
      BoxFit.fitHeight,
      BoxFit.none,
    ]) {
      // Wrapped first, so each fit has to unwrap it.
      await tester.pumpWidget(build(BoxFit.contain));
      expect(_sizeOf(tester, _textKey), const Size(90, 50));

      await tester.pumpWidget(build(fit));
      expect(_sizeOf(tester, _textKey), const Size(490, 10), reason: '$fit');
    }
  });

  testWidgets("doesn't wrap with unbounded constraints", (
    WidgetTester tester,
  ) async {
    // A Column gives its child unbounded height. Bounded, the 800x100 rect
    // would wrap the text.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            FittedBoxWithSiblings(
              delegate: TestRectsDelegate(
                (constraints, boxSize) => [
                  Rect.fromLTWH(0, 0, constraints.maxWidth, 100),
                ],
              ),
              children: [WrapToFit(child: _text(_words))],
            ),
          ],
        ),
      ),
    );

    expect(_sizeOf(tester, _textKey), const Size(490, 10));
  });

  group('keeps the width', () {
    late List<int> computeCount;
    late ValueNotifier<String> clock;
    late ValueNotifier<String> words;
    late ValueNotifier<double> rowHeight;
    late ValueNotifier<String> siblingWords;
    late TestRectsDelegate delegate;

    setUp(() {
      computeCount = [0];
      clock = ValueNotifier('12:00');
      words = ValueNotifier(_words);
      rowHeight = ValueNotifier(10);
      siblingWords = ValueNotifier(_words);
      delegate = TestRectsDelegate((constraints, boxSize) {
        computeCount[0]++;
        // The box and the sibling both fill the room.
        final rect = Offset.zero & constraints.biggest;
        return [rect, rect];
      });
    });

    tearDown(() {
      clock.dispose();
      words.dispose();
      rowHeight.dispose();
      siblingWords.dispose();
    });

    // Only the parts that change rebuild, so the FittedBoxWithSiblings
    // doesn't, and its delegate stays the same.
    Widget build({
      Size room = const Size(200, 200),
      BoxFit fit = BoxFit.contain,
    }) => _build(
      room: room,
      fit: fit,
      delegate: delegate,
      box: Column(
        key: _boxKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: clock,
            builder: (context, value, child) =>
                _text(value, key: const Key('clock')),
          ),
          ValueListenableBuilder<double>(
            valueListenable: rowHeight,
            builder: (context, value, child) =>
                SizedBox(width: 10, height: value),
          ),
          WrapToFit(
            child: ValueListenableBuilder<String>(
              valueListenable: words,
              builder: (context, value, child) => _text(value),
            ),
          ),
        ],
      ),
      siblings: [
        Center(
          child: WrapToFit(
            child: ValueListenableBuilder<String>(
              valueListenable: siblingWords,
              builder: (context, value, child) =>
                  _text(value, key: const Key('sibling')),
            ),
          ),
        ),
      ],
    );

    // Lays out again, and returns whether that searched for the width:
    // keeping it calls computeRects once, for the rects.
    Future<bool> searches(WidgetTester tester, [Widget? widget]) async {
      computeCount[0] = 0;
      if (widget != null) {
        await tester.pumpWidget(widget);
      } else {
        await tester.pump();
      }
      return computeCount[0] > 1;
    }

    testWidgets('while nothing it depends on changes', (
      WidgetTester tester,
    ) async {
      expect(await searches(tester, build()), isTrue);

      // As on a clock tick.
      clock.value = '12:01';
      expect(await searches(tester), isFalse);
    });

    testWidgets('while a text in a sibling changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(build());

      // A WrapToFit in a sibling never wraps. Its change lays out only the
      // sibling, so the clock tick after it is the next layout.
      siblingWords.value = '$_words aaaa';
      await tester.pump();
      clock.value = '12:01';
      expect(await searches(tester), isFalse);
    });

    testWidgets('until the text changes', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final size = _sizeOf(tester, _textKey);

      words.value = '$_words aaaa aaaa';
      expect(await searches(tester), isTrue);
      expect(_sizeOf(tester, _textKey), isNot(size));
    });

    testWidgets('until the room changes', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final size = _sizeOf(tester, _textKey);

      expect(await searches(tester, build(room: const Size(400, 100))), isTrue);
      expect(_sizeOf(tester, _textKey), isNot(size));
    });

    testWidgets("until the box's size changes", (WidgetTester tester) async {
      await tester.pumpWidget(build());

      rowHeight.value = 100;
      expect(await searches(tester), isTrue);
    });

    testWidgets('until the fit changes', (WidgetTester tester) async {
      await tester.pumpWidget(build());
      final size = _sizeOf(tester, _textKey);

      expect(await searches(tester, build(fit: BoxFit.scaleDown)), isTrue);
      expect(_sizeOf(tester, _textKey), isNot(size));
    });

    testWidgets('until the delegate changes', (WidgetTester tester) async {
      await tester.pumpWidget(build());

      // A new delegate whose shouldRelayout returns true, though its rects
      // are the same.
      delegate = TestRectsDelegate(delegate.rectsFor);
      expect(await searches(tester, build()), isTrue);
    });
  });

  testWidgets('keeps the width while expandBox grows the box', (
    WidgetTester tester,
  ) async {
    // A row gives its child all the width it wants, so only the wrap width
    // keeps the text from going back to one line as the row grows.
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        expandBox: Axis.horizontal,
        box: Row(
          key: _boxKey,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [WrapToFit(child: _text(_words))],
        ),
      ),
    );

    // Two words a line, 90x50, at a scale of 2, grown to fill the 200 wide
    // room.
    expect(_sizeOf(tester, _textKey), const Size(90, 50));
    expect(_sizeOf(tester, _boxKey), const Size(100, 50));
  });

  testWidgets('wraps in a box that asks for its intrinsic width', (
    WidgetTester tester,
  ) async {
    // An IntrinsicWidth is how a Column in the box, which is laid out with no
    // constraints, can stretch its children.
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        box: IntrinsicWidth(
          key: _boxKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [WrapToFit(child: _text(_words))],
          ),
        ),
      ),
    );

    // Two words a line, five lines, at a scale of 2.
    expect(_sizeOf(tester, _textKey).height, 50);
    expect(_scaleOf(tester), moreOrLessEquals(2));
  });

  testWidgets('wraps in a box that asks for its intrinsic height', (
    WidgetTester tester,
  ) async {
    // An IntrinsicHeight is how a Row in the box can stretch a bar beside the
    // text to the text's height.
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        box: IntrinsicHeight(
          key: _boxKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 10),
              WrapToFit(child: _text(_words)),
            ],
          ),
        ),
      ),
    );

    // Two words a line, 90x50, beside the bar, at a scale of 2.
    expect(_sizeOf(tester, _textKey), const Size(90, 50));
    expect(_scaleOf(tester), 2);
  });

  testWidgets('a dry layout uses the width the last layout picked', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        box: Column(
          key: _boxKey,
          mainAxisSize: MainAxisSize.min,
          children: [WrapToFit(child: _text(_words))],
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byKey(_boxKey));
    expect(box.size, const Size(90, 50));
    expect(box.getDryLayout(const BoxConstraints()), box.size);
  });

  testWidgets("doesn't wrap a text in a sibling", (WidgetTester tester) async {
    const siblingTextKey = Key('sibling text');
    await tester.pumpWidget(
      _build(
        room: const Size(200, 100),
        delegate: TestRectsDelegate(
          (constraints, boxSize) => [
            Offset.zero & constraints.biggest,
            const Rect.fromLTWH(0, 0, 100, 100),
          ],
        ),
        box: WrapToFit(key: _boxKey, child: _text(_words)),
        siblings: [
          OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: WrapToFit(child: _text(_words, key: siblingTextKey)),
          ),
        ],
      ),
    );

    expect(_sizeOf(tester, _textKey), const Size(90, 50));
    expect(_sizeOf(tester, siblingTextKey), const Size(490, 10));
  });

  group('unwraps when moved', () {
    testWidgets('out of every FittedBoxWithSiblings', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _build(
          room: const Size(200, 100),
          box: WrapToFit(key: key, child: _text(_words)),
        ),
      );
      expect(_sizeOf(tester, _textKey), const Size(90, 50));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: WrapToFit(key: key, child: _text(_words)),
          ),
        ),
      );

      expect(_sizeOf(tester, _textKey), const Size(490, 10));
    });

    testWidgets('into a sibling of another FittedBoxWithSiblings', (
      WidgetTester tester,
    ) async {
      // Only the sibling lays out again, since its tight constraints make it
      // a relayout boundary: the other FittedBoxWithSiblings doesn't.
      final key = GlobalKey();
      final delegate = TestRectsDelegate(
        (constraints, boxSize) => [
          Offset.zero & constraints.biggest,
          Offset.zero & constraints.biggest,
        ],
      );
      Widget build({required bool moved}) {
        final text = WrapToFit(key: key, child: _text(_words));
        return Column(
          children: [
            _build(
              room: const Size(200, 100),
              box: moved ? const SizedBox() : text,
            ),
            _build(
              room: const Size(200, 100),
              delegate: delegate,
              box: const SizedBox(),
              siblings: [
                OverflowBox(
                  minWidth: 0,
                  maxWidth: double.infinity,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: moved ? text : null,
                ),
              ],
            ),
          ],
        );
      }

      await tester.pumpWidget(build(moved: false));
      expect(_sizeOf(tester, _textKey), const Size(90, 50));

      await tester.pumpWidget(build(moved: true));
      expect(_sizeOf(tester, _textKey), const Size(490, 10));
    });
  });
}

Widget _text(String data, {Key key = _textKey}) => Text(
  data,
  key: key,
  style: const TextStyle(fontSize: 10),
  textWidthBasis: TextWidthBasis.longestLine,
);

// The box's rect fills the room.
List<Rect> _fill(BoxConstraints constraints, Size boxSize) => [
  Offset.zero & constraints.biggest,
];

// The box's rect is as wide as the room, at the box's own shape, and as high
// as the room allows with 50 left for the sibling below it.
List<Rect> _followTheBox(BoxConstraints constraints, Size boxSize) {
  final room = constraints.biggest;
  final height = math.min(
    room.width * boxSize.height / boxSize.width,
    room.height - 50,
  );
  return [
    Rect.fromLTWH(0, 0, room.width, height),
    Rect.fromLTWH(0, height, room.width, room.height - height),
  ];
}

// Tables beside the box, in as many 40 wide columns as fit beside it at the
// room's height, and the box's rect the rest of the room.
List<Rect> _tablesBeside(BoxConstraints constraints, Size boxSize) {
  final room = constraints.biggest;
  final boxWidth = room.height * boxSize.width / boxSize.height;
  final columns = math.max(0, ((room.width - boxWidth) / 40).floor());
  final tables = math.min(columns * 40.0, room.width - 1);
  return [
    Rect.fromLTWH(0, 0, room.width - tables, room.height),
    Rect.fromLTWH(room.width - tables, 0, tables, room.height),
  ];
}

// The box's rect beside the sibling's, wider for a wider box, in 20 steps for
// each factor of e in the box's shape, so it changes between nearly any two
// shapes the search asks about.
List<Rect> _stepsWithTheBox(BoxConstraints constraints, Size boxSize) {
  final room = constraints.biggest;
  final steps = (20 * math.log(boxSize.width / boxSize.height)).floor();
  final width = room.width * (0.5 + 0.5 / (1 + math.exp(-steps / 20)));
  return [
    Rect.fromLTWH(0, 0, width, room.height),
    Rect.fromLTWH(width, 0, room.width - width, room.height),
  ];
}

Widget _build({
  required Size room,
  required Widget box,
  FittedBoxWithSiblingsDelegate? delegate,
  BoxFit fit = BoxFit.contain,
  Axis? expandBox,
  List<Widget> siblings = const [],
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox.fromSize(
      size: room,
      child: FittedBoxWithSiblings(
        fit: fit,
        expandBox: expandBox,
        delegate: delegate ?? const TestRectsDelegate(_fill),
        children: [box, ...siblings],
      ),
    ),
  ),
);

Size _sizeOf(WidgetTester tester, Key key) =>
    tester.renderObject<RenderBox>(find.byKey(key)).size;

// The scale the box is painted at.
double _scaleOf(WidgetTester tester) =>
    tester.getRect(find.byKey(_boxKey)).width / _sizeOf(tester, _boxKey).width;
