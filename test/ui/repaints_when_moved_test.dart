import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/ui/glass/repaints_when_moved.dart';

/// Liquid glass draws a surface where it was told the surface is, as it paints. A card moved
/// without painting — pushed down a list by the card above it growing, carried by a page's
/// transition — was drawn as its old outline inside its new place, the rest of it lit as
/// rim. These check that a surface that moves is painted again where it now is.
void main() {
  RenderProbe probe(WidgetTester tester) => tester.renderObject<RenderProbe>(find.byType(Probe));

  testWidgets('pushed down a list by the item above growing, it paints again where it is', (
    tester,
  ) async {
    final above = ValueNotifier<double>(100);
    addTearDown(above.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<double>(
          valueListenable: above,
          builder: (context, height, _) => ListView(
            children: [
              SizedBox(height: height),
              const Probe(child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
    expect(probe(tester).paintedRect?.top, 100);
    final paints = probe(tester).paints;

    above.value = 240;
    await tester.pump();
    // The list moved the item's layer, and painting it was left to the frame after.
    await tester.pump();
    expect(probe(tester).paints, greaterThan(paints));
    expect(probe(tester).paintedRect?.top, 240);
    expect(probe(tester).movedSincePaint, isFalse);
  });

  testWidgets('carried by a transform it does not paint under, it paints again where it ends', (
    tester,
  ) async {
    final shift = ValueNotifier<double>(0);
    addTearDown(shift.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<double>(
          valueListenable: shift,
          builder: (context, dx, child) => Transform.translate(offset: Offset(dx, 0), child: child),
          child: const RepaintBoundary(
            child: Align(
              alignment: Alignment.topLeft,
              child: Probe(child: SizedBox(width: 80, height: 40)),
            ),
          ),
        ),
      ),
    );
    expect(probe(tester).paintedRect?.left, 0);

    shift.value = 30;
    await tester.pump();
    await tester.pump();
    expect(probe(tester).paintedRect?.left, 30);
  });

  testWidgets('one that has not moved is left alone', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Probe(child: SizedBox(width: 80, height: 40)),
      ),
    );
    expect(RepaintsWhenMoved.repaintMoved(), 0);
    final paints = probe(tester).paints;
    await tester.pump();
    expect(probe(tester).paints, paints);
  });
}

class Probe extends SingleChildRenderObjectWidget {
  const Probe({super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderProbe();
}

/// Paints as liquid glass does: saying where it is as it paints.
class RenderProbe extends RenderProxyBox with RepaintsWhenMoved {
  int paints = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    paints++;
    paintedAt(onScreen);
    super.paint(context, offset);
  }
}
