import 'package:capywake/design/capy_card.dart';
import 'package:capywake/design/capy_toggle.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/design/section_header.dart';
import 'package:capywake/design/theme.dart';
import 'package:capywake/design/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: capyTheme(brightness: brightness),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('CapyCard', () {
    testWidgets('renders its child inside a bordered surface', (tester) async {
      await tester.pumpWidget(_host(const CapyCard(child: Text('hello'))));

      expect(find.text('hello'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CapyCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, CapyColors.surface);
      expect(decoration.border, isNotNull);
    });

    testWidgets('is not tappable unless given onTap', (tester) async {
      await tester.pumpWidget(_host(const CapyCard(child: Text('hello'))));
      expect(
        find.descendant(
          of: find.byType(CapyCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('fires onTap when given one', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(CapyCard(onTap: () => taps++, child: const Text('hello'))),
      );
      await tester.tap(find.text('hello'));
      expect(taps, 1);
    });

    testWidgets('swaps to the dark surface in dark mode', (tester) async {
      await tester.pumpWidget(
        _host(
          const CapyCard(child: Text('hello')),
          brightness: Brightness.dark,
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CapyCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, CapyColors.darkSurface);
    });
  });

  group('CapyToggle', () {
    testWidgets('paints at the mockup size inside a 44pt tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'alarm',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );

      // Tier A binds the painted track; a core alarm control still has to be
      // reachable half-asleep, so the hit area is the larger of the two.
      final painted = tester.getSize(
        find
            .descendant(
              of: find.byType(CapyToggle),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(painted.width, closeTo(CapyToggle.homeTrack.width, 0.1));
      expect(painted.height, closeTo(CapyToggle.homeTrack.height, 0.1));

      final target = tester.getSize(find.byType(CapyToggle));
      expect(target.height, greaterThanOrEqualTo(44.0));
    });

    testWidgets('exposes toggled state to semantics when on', (tester) async {
      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'alarm',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CapyToggle)),
        matchesSemantics(
          label: 'alarm',
          hasToggledState: true,
          isToggled: true,
        ),
      );
    });

    testWidgets('exposes toggled state to semantics when off', (tester) async {
      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: false,
            onChanged: (_) {},
            semanticLabel: 'alarm',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CapyToggle)),
        matchesSemantics(label: 'alarm', hasToggledState: true),
      );
    });

    testWidgets('state is carried by knob position, not colour alone', (
      tester,
    ) async {
      // Palette constraint F1: success is 2.68:1 on cream, under the 3:1 UI
      // minimum, so position must distinguish on from off.
      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: false,
            onChanged: (_) {},
            semanticLabel: 'a',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );
      final offX = tester.getCenter(find.byType(Container).first).dx;

      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'a',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );
      final onX = tester.getCenter(find.byType(Container).first).dx;

      expect(onX, greaterThan(offX));
    });

    testWidgets('reports the flipped value on tap', (tester) async {
      bool? got;
      await tester.pumpWidget(
        _host(
          CapyToggle(
            value: false,
            onChanged: (v) => got = v,
            semanticLabel: 'alarm',
            trackSize: CapyToggle.homeTrack,
          ),
        ),
      );
      await tester.tap(find.byType(CapyToggle));
      expect(got, isTrue);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows its title alone when given no action', (tester) async {
      await tester.pumpWidget(_host(const SectionHeader(title: 'Games')));
      expect(find.text('Games'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('fires the trailing action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SectionHeader(
            title: 'Games',
            actionLabel: 'See All',
            onAction: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('See All'));
      expect(taps, 1);
    });

    testWidgets('the action target is at least 44pt tall', (tester) async {
      await tester.pumpWidget(
        _host(
          SectionHeader(
            title: 'Games',
            actionLabel: 'See All',
            onAction: () {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(44),
      );
    });
  });

  group('MeadowFooter', () {
    testWidgets('matches the measured band height', (tester) async {
      await tester.pumpWidget(_host(const MeadowFooter()));
      expect(
        tester.getSize(find.byType(MeadowFooter)).height,
        closeTo(65.2, 0.1),
      );
    });

    testWidgets('is decor and carries no semantics', (tester) async {
      await tester.pumpWidget(_host(const MeadowFooter()));
      expect(
        find.descendant(
          of: find.byType(MeadowFooter),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders in dark mode without throwing', (tester) async {
      await tester.pumpWidget(
        _host(const MeadowFooter(), brightness: Brightness.dark),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
