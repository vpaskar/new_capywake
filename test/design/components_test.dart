import 'package:capywake/core/models/alarm.dart';
import 'package:capywake/design/art.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/capy_nav_bar.dart';
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
  group('CapyButton', () {
    testWidgets('a screen reader can press it', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(CapyButton(label: 'Add Alarm', onPressed: () => taps++)),
      );

      tester.semantics.tap(find.semantics.byLabel('Add Alarm'));
      await tester.pump();

      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('shows its label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          CapyButton(label: 'Add Alarm', onPressed: () => taps++),
        ),
      );

      expect(find.text('Add Alarm'), findsOneWidget);
      await tester.tap(find.text('Add Alarm'));
      expect(taps, 1);
    });

    testWidgets('does not fire when disabled', (tester) async {
      await tester.pumpWidget(
        _host(const CapyButton(label: 'Add Alarm', onPressed: null)),
      );
      await tester.tap(find.text('Add Alarm'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('matches the measured height from the mockup', (tester) async {
      await tester.pumpWidget(
        _host(CapyButton(label: 'Add Alarm', onPressed: () {})),
      );
      final size = tester.getSize(find.byType(CapyButton));
      expect(size.height, closeTo(55.4, 0.1));
    });

    testWidgets('exposes one button to semantics', (tester) async {
      await tester.pumpWidget(
        _host(CapyButton(label: 'Add Alarm', onPressed: () {})),
      );
      expect(
        tester.getSemantics(find.byType(CapyButton)),
        matchesSemantics(
          label: 'Add Alarm',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('does not truncate a long localized label', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 370,
            child: CapyButton(
              label: 'Neuen Wecker hinzufügen und speichern',
              onPressed: () {},
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.text('Neuen Wecker hinzufügen und speichern'),
      );
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });
  });

  group('CapyNavBar', () {
    List<CapyNavDestination> destinations() => const [
      CapyNavDestination(icon: Icons.home_rounded, label: 'Home'),
      CapyNavDestination(icon: Icons.access_time_rounded, label: 'Alarms'),
      CapyNavDestination(icon: Icons.bar_chart_rounded, label: 'Stats'),
    ];

    testWidgets('renders every destination', (tester) async {
      await tester.pumpWidget(
        _host(
          CapyNavBar(
            destinations: destinations(),
            currentIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Alarms'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
    });

    testWidgets('reports the tapped index', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _host(
          CapyNavBar(
            destinations: destinations(),
            currentIndex: 0,
            onSelected: (i) => selected = i,
          ),
        ),
      );
      await tester.tap(find.text('Stats'));
      expect(selected, 2);
    });

    testWidgets('tints only the selected tab with the accent', (tester) async {
      await tester.pumpWidget(
        _host(
          CapyNavBar(
            destinations: destinations(),
            currentIndex: 1,
            onSelected: (_) {},
          ),
        ),
      );

      final icons = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.color)
          .toList();
      expect(icons.where((c) => c == CapyColors.accent), hasLength(1));
    });

    testWidgets('marks the selected tab for screen readers', (tester) async {
      await tester.pumpWidget(
        _host(
          CapyNavBar(
            destinations: destinations(),
            currentIndex: 1,
            onSelected: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Alarms')),
        matchesSemantics(
          label: 'Alarms',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
    });
  });

  group('CapyArt catalogue', () {
    test('an alarm picture resolves by choice, then by position', () {
      expect(CapyArt.alarmThumbnail(artId: Alarm.noArtId, index: 0), isNull);
      expect(
        CapyArt.alarmThumbnail(artId: 'thumb.walk', index: 0)!.id,
        'thumb.walk',
      );
      expect(
        CapyArt.alarmThumbnail(artId: null, index: 1)!.id,
        'thumb.workout',
      );
      expect(
        CapyArt.alarmThumbnail(artId: 'thumb.retired', index: 1)!.id,
        'thumb.workout',
      );
    });

    test('empty states use a cutout, never a painted panel', () {
      expect(CapyArt.emptyStateMascot.use, isNot(ArtUse.thumbnail));
    });

    test('every asset declares the pixels its render box needs', () {
      for (final asset in CapyArt.all) {
        expect(
          asset.requiredPixels,
          (asset.use.renderBoxPt * 3).ceil(),
          reason: '${asset.id} must be sized for a 3x device',
        );
      }
    });

    test('ids are unique', () {
      final ids = CapyArt.all.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('paths are unique', () {
      final paths = CapyArt.all.map((a) => a.path).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });
  });
}
