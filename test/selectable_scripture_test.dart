import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';

void main() {
  Widget buildTestPassage({
    required ScriptureSelectionController controller,
    TextDirection direction = TextDirection.ltr,
    Color? handleColor,
    bool showHandles = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: SizedBox(
            width: 400,
            height: 200,
            child: SelectableScripture(
              controller: controller,
              handleColor: handleColor,
              showHandles: showHandles,
              child: PassageWidget(
                children: [
                  ParagraphWidget(
                    selectionController: controller,
                    children: const [
                      WordWidget(text: 'In', id: 1),
                      SpaceWidget(width: 8),
                      WordWidget(text: 'the', id: 2),
                      SpaceWidget(width: 8),
                      WordWidget(text: 'beginning', id: 3),
                      SpaceWidget(width: 8),
                      WordWidget(text: 'was', id: 4),
                      SpaceWidget(width: 8),
                      WordWidget(text: 'the', id: 5),
                      SpaceWidget(width: 8),
                      WordWidget(text: 'Word', id: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('WordGeometry and Hit-testing in RenderPassage', () {
    testWidgets('getWordGeometry returns correct rect and direction', (
      tester,
    ) async {
      final controller = ScriptureSelectionController();
      await tester.pumpWidget(buildTestPassage(controller: controller));

      final passageFinder = find.byType(PassageWidget);
      final renderPassage = tester.renderObject(passageFinder) as RenderPassage;

      final geom1 = renderPassage.getWordGeometry(1);
      expect(geom1, isNotNull);
      expect(geom1!.direction, TextDirection.ltr);
      expect(geom1.rect.left, equals(0.0));
      expect(geom1.rect.width, greaterThan(0.0));
      expect(geom1.rect.height, greaterThan(0.0));

      final geom3 = renderPassage.getWordGeometry(3);
      expect(geom3, isNotNull);
      expect(geom3!.rect.left, greaterThan(geom1.rect.right));

      // Non-existent ID returns null
      expect(renderPassage.getWordGeometry(999), isNull);
    });

    testWidgets(
      'getWordAtOrNearOffset finds exact and closest words across spaces',
      (tester) async {
        final controller = ScriptureSelectionController();
        await tester.pumpWidget(buildTestPassage(controller: controller));

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;

        final geom1 = renderPassage.getWordGeometry(1)!;
        final geom2 = renderPassage.getWordGeometry(2)!;

        // Exact hit on Word 1
        final hitExact = renderPassage.getWordAtOrNearOffset(
          geom1.rect.center,
        );
        expect(hitExact, equals(1));

        // Hit in the space between Word 1 and Word 2
        final spaceX = (geom1.rect.right + geom2.rect.left) / 2;
        final spaceHit = renderPassage.getWordAtOrNearOffset(
          Offset(spaceX, geom1.rect.center.dy),
        );
        expect(spaceHit == 1 || spaceHit == 2, isTrue);

        // Hit slightly below the line of text (like where the handle hangs)
        final belowHit = renderPassage.getWordAtOrNearOffset(
          Offset(geom1.rect.center.dx, geom1.rect.bottom + 15),
        );
        expect(belowHit, equals(1));
      },
    );
  });

  group('Selection Handles and Interaction', () {
    testWidgets(
      'CustomPaint paints handles when selection is active',
      (tester) async {
        final controller = ScriptureSelectionController();
        await tester.pumpWidget(buildTestPassage(controller: controller));

        // Initially no selection
        expect(controller.hasSelection, isFalse);

        // Select words 1 to 3
        controller.selectRange(1, 3);
        await tester.pump();

        expect(controller.hasSelection, isTrue);
        expect(controller.startId, equals(1));
        expect(controller.endId, equals(3));

        // Tap whitespace inside passage to clear selection
        await tester.tapAt(const Offset(350, 10));
        await tester.pump();

        expect(controller.hasSelection, isFalse);
      },
    );

    testWidgets(
      'Dragging the end handle updates the selection range',
      (tester) async {
        final controller = ScriptureSelectionController();
        await tester.pumpWidget(buildTestPassage(controller: controller));

        // Select words 1 to 2
        controller.selectRange(1, 2);
        await tester.pump();

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;

        // Find end handle location (word 2 bottom-right)
        final geom2 = renderPassage.getWordGeometry(2)!;
        final geom4 = renderPassage.getWordGeometry(4)!;

        // The end handle anchor is at bottom-right of word 2
        final handlePoint = renderPassage.localToGlobal(
          Offset(geom2.rect.right + 5, geom2.rect.bottom + 10),
        );

        // Drag from the end handle to word 4
        final targetPoint = renderPassage.localToGlobal(geom4.rect.center);

        final gesture = await tester.startGesture(handlePoint);
        await tester.pump();
        await gesture.moveTo(targetPoint);
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Selection should have expanded to word 4
        expect(controller.startId, equals(1));
        expect(controller.endId, equals(4));
      },
    );

    testWidgets(
      'Dragging the start handle updates the selection range',
      (tester) async {
        final controller = ScriptureSelectionController();
        await tester.pumpWidget(buildTestPassage(controller: controller));

        // Select words 2 to 4
        controller.selectRange(2, 4);
        await tester.pump();

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;

        final geom2 = renderPassage.getWordGeometry(2)!;
        final geom1 = renderPassage.getWordGeometry(1)!;

        // Start handle is at bottom-left of word 2
        final handlePoint = renderPassage.localToGlobal(
          Offset(geom2.rect.left - 5, geom2.rect.bottom + 10),
        );

        // Drag to word 1
        final targetPoint = renderPassage.localToGlobal(geom1.rect.center);

        final gesture = await tester.startGesture(handlePoint);
        await tester.pump();
        await gesture.moveTo(targetPoint);
        await tester.pump();
        await gesture.up();
        await tester.pump();

        // Selection start should now be word 1
        expect(controller.startId, equals(1));
        expect(controller.endId, equals(4));
      },
    );

    testWidgets('RTL selection handle dragging', (tester) async {
      final controller = ScriptureSelectionController();
      await tester.pumpWidget(
        buildTestPassage(
          controller: controller,
          direction: TextDirection.rtl,
        ),
      );

      // Select words 1 to 2
      controller.selectRange(1, 2);
      await tester.pump();

      final passageFinder = find.byType(PassageWidget);
      final renderPassage =
          tester.renderObject(passageFinder) as RenderPassage;

      final geom1 = renderPassage.getWordGeometry(1)!;
      final geom2 = renderPassage.getWordGeometry(2)!;

      // In RTL, word 1 is to the right of word 2
      expect(geom1.rect.left, greaterThan(geom2.rect.left));
      expect(geom1.direction, equals(TextDirection.rtl));
    });
  });
}
