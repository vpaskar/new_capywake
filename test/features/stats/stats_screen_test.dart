import 'package:capywake/core/models/models.dart';
import 'package:capywake/design/meadow_footer.dart';
import 'package:capywake/features/stats/sleep_segment.dart';
import 'package:capywake/features/stats/stat_tile.dart';
import 'package:capywake/features/stats/stats_notice.dart';
import 'package:capywake/features/stats/stats_screen.dart';
import 'package:capywake/features/stats/stats_segment_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'stats_harness.dart';

Alarm _alarm(String id) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: id,
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 15,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.normalButton,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

AlarmOccurrence _dismissed(String id, DateTime at) => AlarmOccurrence(
  id: id,
  alarmId: 'a1',
  scheduledAt: at,
  softStartAt: null,
  status: AlarmStatus.dismissed,
  triggeredAt: at,
  dismissedAt: at.add(const Duration(minutes: 1)),
  snoozeCount: 0,
  note: '',
);

void main() {
  setUpAll(initializeDateFormatting);

  group(
    'the default state is empty, and says so without inventing a number',
    () {
      testWidgets('every value slot renders the no-value token', (
        tester,
      ) async {
        await pumpStats(tester);
        final l10n = l10nOf(tester);

        await tapSegment(tester, l10n.statsSegmentAlarms);

        final tiles = tester.widgetList<StatTile>(find.byType(StatTile));
        expect(tiles, isNotEmpty);
        for (final tile in tiles) {
          expect(
            tile.value,
            isNull,
            reason:
                'A tile given a value on a fresh install states something '
                'about a user who has no data. ${tile.label} had one.',
          );
        }
        expect(find.text(l10n.statsNoValue), findsWidgets);
      });

      testWidgets('no figure from the mockup is rendered anywhere', (
        tester,
      ) async {
        await pumpStats(tester);

        final l10n = l10nOf(tester);
        final labels = [
          l10n.statsSegmentSleep,
          l10n.statsSegmentAlarms,
          l10n.statsSegmentGames,
        ];
        for (final label in labels) {
          await tapSegment(tester, label);

          for (final fabricated in [
            '7 h 32 m',
            '+18 min',
            '6 days',
            'Best: 14 days',
            '8 h',
            '94%',
            '10:28',
            '7:00',
            '52 h 44 m',
            '7:20',
            '8:02',
          ]) {
            expect(
              find.textContaining(fabricated, findRichText: true),
              findsNothing,
              reason: "$fabricated is one of the mockup's invented figures.",
            );
          }
        }
      });

      testWidgets('the empty notice explains the dashes', (tester) async {
        await pumpStats(tester);
        final l10n = l10nOf(tester);

        await tapSegment(tester, l10n.statsSegmentAlarms);

        expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
        expect(find.text(l10n.historyEmptyBody), findsOneWidget);
      });

      testWidgets('the card envelopes survive, so the screen keeps its shape', (
        tester,
      ) async {
        await pumpStats(tester);
        final l10n = l10nOf(tester);

        await tapSegment(tester, l10n.statsSegmentAlarms);

        expect(find.byType(StatTile), findsNWidgets(5));
      });
    },
  );

  group('a value appears only once it is measured', () {
    testWidgets('a dismissed occurrence gives the on-time tile a number', (
      tester,
    ) async {
      final now = DateTime(2026, 11, 17, 9, 41);
      await pumpStats(
        tester,
        alarms: [_alarm('a1')],
        occurrences: [_dismissed('o1', now.subtract(const Duration(days: 1)))],
        now: now,
      );
      final l10n = l10nOf(tester);

      await tapSegment(tester, l10n.statsSegmentAlarms);

      final tiles = tester.widgetList<StatTile>(find.byType(StatTile));
      expect(
        tiles.where((t) => t.value != null),
        isNotEmpty,
        reason: 'With a real occurrence in the window, tiles carry values.',
      );
      expect(find.text(l10n.historyEmptyTitle), findsNothing);
    });

    testWidgets('an occurrence outside the window leaves the screen empty', (
      tester,
    ) async {
      final now = DateTime(2026, 11, 17, 9, 41);
      await pumpStats(
        tester,
        alarms: [_alarm('a1')],
        occurrences: [_dismissed('o1', now.subtract(const Duration(days: 90)))],
        now: now,
      );
      final l10n = l10nOf(tester);

      await tapSegment(tester, l10n.statsSegmentAlarms);

      expect(find.text(l10n.historyEmptyTitle), findsOneWidget);
    });
  });

  group('the segments', () {
    testWidgets('Sleep is the default and states why it has nothing', (
      tester,
    ) async {
      await pumpStats(tester);
      final l10n = l10nOf(tester);

      expect(find.byType(SleepSegment), findsOneWidget);
      expect(find.text(l10n.statsSleepUnavailableTitle), findsOneWidget);
    });

    testWidgets('Sleep never tells the user to press a Connect control', (
      tester,
    ) async {
      await pumpStats(tester);
      final l10n = l10nOf(tester);

      expect(
        find.text(l10n.sleepHistoryEmpty),
        findsNothing,
        reason:
            'That string says "Connect Health" and there is no such '
            'control anywhere in the app.',
      );
      for (final word in ['Connect', 'Health Connect']) {
        expect(find.textContaining(word, findRichText: true), findsNothing);
      }
    });

    testWidgets('Games states that nothing is recorded, with no score', (
      tester,
    ) async {
      await pumpStats(tester);
      final l10n = l10nOf(tester);

      await tapSegment(tester, l10n.statsSegmentGames);

      expect(find.text(l10n.statsGamesNotRecordedTitle), findsOneWidget);
      for (final banned in ['Score', 'Streak', 'Best', 'Record', 'Rank']) {
        expect(find.textContaining(banned, findRichText: true), findsNothing);
      }
    });

    testWidgets('each segment is reachable and keeps the switcher', (
      tester,
    ) async {
      await pumpStats(tester);
      final l10n = l10nOf(tester);

      for (final label in [
        l10n.statsSegmentAlarms,
        l10n.statsSegmentGames,
        l10n.statsSegmentSleep,
      ]) {
        await tapSegment(tester, label);
        expect(find.byType(StatsSegmentSwitcher), findsOneWidget);
      }
    });
  });

  group('geometry', () {
    testWidgets('the hero band and meadow are Stats own measurements', (
      tester,
    ) async {
      await pumpStats(tester);

      expect(StatsScreen.heroBandHeight, 111.5);
      expect(StatsScreen.meadowHeight, 79.9);
      expect(
        tester.getSize(find.byType(MeadowFooter)).height,
        closeTo(StatsScreen.meadowHeight, 0.1),
      );
    });

    testWidgets('the switcher clears the 44 pt tap floor', (tester) async {
      await pumpStats(tester);

      expect(
        tester.getSize(find.byType(StatsSegmentSwitcher)).height,
        greaterThanOrEqualTo(44.0),
      );
    });

    testWidgets('the pill renders the height it was given', (tester) async {
      await pumpStats(tester);

      // Measure what it renders, not the constant it was handed: the first
      // build sized the pill to its text and came out 33.7 against 30.9.
      final pill = find.descendant(
        of: find.byType(StatsSegmentSwitcher),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == StatsSegmentSwitcher.trackHeight,
        ),
      );
      expect(pill, findsNWidgets(StatsSegment.values.length));
      expect(
        tester.getSize(pill.first).height,
        closeTo(StatsSegmentSwitcher.trackHeight, 0.1),
      );
    });
  });

  group('accessibility and localisation', () {
    testWidgets('the no-value token is spoken as words, not punctuation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpStats(tester);
      final l10n = l10nOf(tester);

      await tapSegment(tester, l10n.statsSegmentAlarms);

      // The list merges its children into one node, so the assertion is on
      // the announced string rather than on a node per tile.
      final spoken = tester.getSemantics(find.byType(StatTile).first).label;
      expect(spoken, contains(l10n.statsNoValueSemanticLabel));
      expect(
        spoken,
        isNot(contains(l10n.statsNoValue)),
        reason: 'A screen reader announcing an em dash has said nothing.',
      );
      semantics.dispose();
    });

    testWidgets('Arabic renders without overflow', (tester) async {
      await pumpStats(tester, locale: const Locale('ar'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text renders without overflow', (tester) async {
      await pumpStats(tester, textScaler: const TextScaler.linear(1.6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the notice art is hidden from screen readers', (tester) async {
      await pumpStats(tester);
      expect(find.byType(StatsNotice), findsOneWidget);
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });
  });
}
