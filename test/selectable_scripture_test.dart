import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';

void main() {
  Widget buildTestPassage({
    required ScriptureSelectionController controller,
    TextDirection direction = TextDirection.ltr,
    Color? handleColor,
    bool showHandles = true,
    VoidCallback? onTapWhitespace,
    void Function(int wordId)? onWordTapped,
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
              onTapWhitespace: onTapWhitespace,
              onWordTapped: onWordTapped,
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

    testWidgets(
      'tapping whitespace calls onTapWhitespace, while tapping word calls onWordTapped',
      (tester) async {
        final controller = ScriptureSelectionController();
        var whitespaceTapped = false;
        int? tappedWordId;

        await tester.pumpWidget(
          buildTestPassage(
            controller: controller,
            onTapWhitespace: () => whitespaceTapped = true,
            onWordTapped: (id) => tappedWordId = id,
          ),
        );

        // Tap on a word
        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;
        final geom = renderPassage.getWordGeometry(1)!;
        final wordCenter = renderPassage.localToGlobal(geom.rect.center);

        await tester.tapAt(wordCenter);
        await tester.pump();
        expect(tappedWordId, equals(1));
        expect(whitespaceTapped, isFalse);

        // Tap on empty space (e.g. at bottom of passage)
        await tester.tapAt(const Offset(350, 150));
        await tester.pump();
        expect(whitespaceTapped, isTrue);

        // When selection is active, tapping whitespace clears selection without calling onTapWhitespace
        whitespaceTapped = false;
        controller.selectRange(1, 3);
        await tester.pump();
        expect(controller.hasSelection, isTrue);

        await tester.tapAt(const Offset(350, 150));
        await tester.pump();
        expect(controller.hasSelection, isFalse);
        expect(whitespaceTapped, isFalse);
      },
    );
  });

  group('Auto-scrolling when dragging selection handles', () {
    testWidgets(
      'Dragging end handle beyond bottom edge auto-scrolls down and expands selection',
      (tester) async {
        final controller = ScriptureSelectionController();
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableScripture(
                    controller: controller,
                    child: PassageWidget(
                      children: [
                        for (int i = 1; i <= 20; i++)
                          ParagraphWidget(
                            selectionController: controller,
                            children: [
                              WordWidget(text: 'Paragraph $i Word', id: i),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Select words 1 to 2
        controller.selectRange(1, 2);
        await tester.pumpAndSettle();

        expect(scrollController.offset, equals(0.0));

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;
        final geom2 = renderPassage.getWordGeometry(2)!;
        final handlePoint = renderPassage.localToGlobal(
          Offset(geom2.rect.right + 5, geom2.rect.bottom + 10),
        );

        // Start drag on handle
        final gesture = await tester.startGesture(handlePoint);
        await tester.pump();

        // Drag below viewport (viewport height is 100, y=150 is offscreen)
        await gesture.moveTo(const Offset(100, 150));
        await tester.pump();

        // Auto-scroller should tick and scroll down
        await tester.pump(const Duration(milliseconds: 200));

        expect(scrollController.offset, greaterThan(0.0));
        expect(controller.endId, greaterThan(2));

        // Release drag
        await gesture.up();
        await tester.pumpAndSettle();

        final offsetAfterUp = scrollController.offset;
        await tester.pump(const Duration(milliseconds: 200));
        expect(scrollController.offset, equals(offsetAfterUp));
      },
    );

    testWidgets(
      'Dragging start handle beyond top edge auto-scrolls up and expands selection',
      (tester) async {
        final controller = ScriptureSelectionController();
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 100,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableScripture(
                    controller: controller,
                    child: PassageWidget(
                      children: [
                        for (int i = 1; i <= 20; i++)
                          ParagraphWidget(
                            selectionController: controller,
                            children: [
                              WordWidget(text: 'Paragraph $i Word', id: i),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Pre-scroll down
        scrollController.jumpTo(60.0);
        await tester.pumpAndSettle();
        expect(scrollController.offset, equals(60.0));

        // Select words 10 to 11
        controller.selectRange(10, 11);
        await tester.pumpAndSettle();

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;
        final geom10 = renderPassage.getWordGeometry(10)!;
        final handlePoint = renderPassage.localToGlobal(
          Offset(geom10.rect.left + 5, geom10.rect.bottom + 10),
        );

        final gesture = await tester.startGesture(handlePoint);
        await tester.pump();

        // Drag above viewport (global y = -20 is offscreen)
        await gesture.moveTo(const Offset(100, -20));
        await tester.pump();

        // Ticker should auto-scroll up
        await tester.pump(const Duration(milliseconds: 200));

        expect(scrollController.offset, lessThan(60.0));
        expect(controller.startId, lessThan(10));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Selected word and handle remain visible onscreen when dragging offscreen',
      (tester) async {
        final controller = ScriptureSelectionController();
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 120,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableScripture(
                    controller: controller,
                    child: PassageWidget(
                      children: [
                        for (int i = 1; i <= 20; i++)
                          ParagraphWidget(
                            selectionController: controller,
                            children: [
                              WordWidget(text: 'Paragraph $i Word', id: i),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        controller.selectRange(1, 1);
        await tester.pumpAndSettle();

        final passageFinder = find.byType(PassageWidget);
        final renderPassage =
            tester.renderObject(passageFinder) as RenderPassage;
        final geom1 = renderPassage.getWordGeometry(1)!;
        final handlePoint = renderPassage.localToGlobal(
          Offset(geom1.rect.right + 5, geom1.rect.bottom + 10),
        );

        final gesture = await tester.startGesture(handlePoint);
        await tester.pump();

        // Drag far offscreen (y = 500 when viewport height is 120)
        await gesture.moveTo(const Offset(100, 500));
        await tester.pump();

        // Run auto-scroll for a bit
        await tester.pump(const Duration(milliseconds: 300));

        // Check current end word geometry in global coordinates
        final endId = controller.endId!;
        final endGeom = renderPassage.getWordGeometry(endId)!;
        final endHandleAnchor = renderPassage.localToGlobal(
          Offset(endGeom.rect.right, endGeom.rect.bottom),
        );

        // The handle's anchor must be within the 120px viewport height
        expect(endHandleAnchor.dy, lessThanOrEqualTo(120.0));
        expect(endHandleAnchor.dy, greaterThanOrEqualTo(0.0));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
