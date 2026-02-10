import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scripture/src/flutter/paragraph.dart';
import 'package:scripture/src/flutter/word.dart';
import 'package:scripture/src/flutter/selection_controller.dart';
import 'package:scripture/src/flutter/space_widget.dart';

void main() {
  /// Custom finder to locate your custom WordWidget by its text property
  Finder findWord(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is WordWidget && widget.text == text,
      description: 'WordWidget containing "$text"',
    );
  }

  Widget buildTestWidget({
    required TextDirection direction,
    required List<Widget> children,
    double width = 300.0,
    ScriptureSelectionController? controller,
    TextAlign textAlign = TextAlign.start,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ParagraphWidget(
              textAlign: textAlign,
              selectionController: controller,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  group('ParagraphWidget Layout', () {
    testWidgets('LTR: Words are positioned Left-to-Right', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          direction: TextDirection.ltr,
          children: const [
            WordWidget(text: 'First', id: 1),
            SpaceWidget(width: 10),
            WordWidget(text: 'Second', id: 2),
          ],
        ),
      );

      // Use custom finder
      final firstFinder = findWord('First');
      final secondFinder = findWord('Second');

      final firstPos = tester.getTopLeft(firstFinder);
      final secondPos = tester.getTopLeft(secondFinder);

      // In LTR, "First" (x=0) should be to the left of "Second" (x>0)
      expect(
        firstPos.dx,
        lessThan(secondPos.dx),
        reason: 'First word should be to the left',
      );

      // Both should be on the same line (y ~ 0)
      expect(firstPos.dy, equals(secondPos.dy));
    });

    testWidgets('RTL: Words are positioned Right-to-Left', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          direction: TextDirection.rtl,
          children: const [
            WordWidget(text: 'First', id: 1), // Logical first
            SpaceWidget(width: 10),
            WordWidget(text: 'Second', id: 2), // Logical second
          ],
        ),
      );

      final firstFinder = findWord('First');
      final secondFinder = findWord('Second');

      final firstPos = tester.getTopLeft(firstFinder);
      final secondPos = tester.getTopLeft(secondFinder);

      // In RTL, "First" is visually on the Right edge. "Second" follows to its Left.
      // Therefore, First.dx > Second.dx
      expect(
        firstPos.dx,
        greaterThan(secondPos.dx),
        reason: 'First word (start) should be to the right of Second word',
      );

      // Both should be on the same line
      expect(firstPos.dy, equals(secondPos.dy));
    });

    testWidgets('LTR: Line Wrapping works correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          direction: TextDirection.ltr,
          width: 100.0,
          children: const [
            WordWidget(text: 'A_Long_Word_Here', id: 1),
            SpaceWidget(width: 50),
            WordWidget(text: 'Wrapped', id: 2),
          ],
        ),
      );

      final firstPos = tester.getTopLeft(findWord('A_Long_Word_Here'));
      final wrappedPos = tester.getTopLeft(findWord('Wrapped'));

      // The second word should be below the first
      expect(wrappedPos.dy, greaterThan(firstPos.dy));

      // The second word should be aligned to the left edge (x=0) in standard LTR
      expect(wrappedPos.dx, equals(0.0));
    });

    testWidgets('RTL: Line Wrapping aligns to the Right', (tester) async {
      const double containerWidth = 100.0;

      await tester.pumpWidget(
        buildTestWidget(
          direction: TextDirection.rtl,
          width: containerWidth,
          children: const [
            WordWidget(text: 'Start', id: 1),
            SpaceWidget(width: 50),
            WordWidget(text: 'Wrapped', id: 2),
          ],
        ),
      );

      final startPos = tester.getTopLeft(findWord('Start'));
      final wrappedFinder = findWord('Wrapped');
      final wrappedTopLeft = tester.getTopLeft(wrappedFinder);

      // Check vertical wrapping
      expect(wrappedTopLeft.dy, greaterThan(startPos.dy));

      // Check alignment:
      // In RTL, the wrapped line should start at the RIGHT edge.
      final wrappedTopRight = tester.getTopRight(wrappedFinder);

      // Allow for small floating point precision differences
      expect(wrappedTopRight.dx, closeTo(containerWidth, 0.1));
    });
  });

  group('Interaction & Hit Testing', () {
    testWidgets(
      'RTL: Hit testing finds the correct word ID at visual location',
      (tester) async {
        final controller = ScriptureSelectionController();

        await tester.pumpWidget(
          buildTestWidget(
            direction: TextDirection.rtl,
            width: 300,
            controller: controller,
            children: const [
              WordWidget(text: 'RightMost', id: 1),
              SpaceWidget(width: 10),
              WordWidget(text: 'LeftNeighbor', id: 2),
            ],
          ),
        );

        // 1. Find visual center using our custom finder
        final rightMostCenter = tester.getCenter(findWord('RightMost'));

        // 2. Get the RenderObject and cast to RenderBox
        final renderBox =
            tester.renderObject(find.byType(ParagraphWidget)) as RenderBox;

        // 3. Perform a Hit Test manually at that exact position
        final result = BoxHitTestResult();
        final localOffset = renderBox.globalToLocal(rightMostCenter);
        final hit = renderBox.hitTest(result, position: localOffset);

        expect(hit, isTrue, reason: 'Hit test should pass');

        // 4. Verify that we actually hit the RenderWord with ID=1
        bool hitCorrectWord = false;
        for (final entry in result.path) {
          if (entry.target is RenderWord) {
            final word = entry.target as RenderWord;
            if (word.id == 1) {
              hitCorrectWord = true;
            }
          }
        }

        expect(
          hitCorrectWord,
          isTrue,
          reason: 'The hit test path should contain Word ID 1',
        );
      },
    );
  });

  group('Alignment Overrides', () {
    testWidgets('RTL + TextAlign.left forces visual left alignment', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          direction: TextDirection.rtl,
          textAlign: TextAlign.left, // Force LTR visual alignment
          width: 300,
          children: const [WordWidget(text: 'Word', id: 1)],
        ),
      );

      final wordPos = tester.getTopLeft(findWord('Word'));

      // Should be at 0.0 (Visual Left)
      expect(wordPos.dx, equals(0.0));
    });
  });
}
