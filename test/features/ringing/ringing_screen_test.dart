import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/design/capy_button.dart';
import 'package:capywake/design/hold_to_act_button.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Alarm _alarm({
  DismissMethod dismissMethod = DismissMethod.normalButton,
  String label = 'Morning',
  int minutes = 7 * 60,
}) {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: label,
    enabled: true,
    targetTimeMinutes: minutes,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: dismissMethod,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

AlarmOccurrence _occurrence({
  int snoozeCount = 0,
  AlarmStatus status = AlarmStatus.triggered,
}) => AlarmOccurrence(
  id: 'o1',
  alarmId: 'a1',
  scheduledAt: DateTime.utc(2026, 5, 21, 5),
  softStartAt: null,
  status: status,
  triggeredAt: DateTime.utc(2026, 5, 21, 5),
  dismissedAt: null,
  snoozeCount: snoozeCount,
  note: '',
);

RingingSession _session({
  Alarm? alarm,
  AlarmOccurrence? occurrence,
  bool snoozeAvailable = true,
  bool isFinalAlarm = false,
  PuzzleEscapeVisibility escapeVisibility = PuzzleEscapeVisibility.available,
}) => RingingSession(
  alarm: alarm ?? _alarm(),
  occurrence: occurrence ?? _occurrence(),
  snoozeAvailable: snoozeAvailable,
  isFinalAlarm: isFinalAlarm,
  escapeVisibility: escapeVisibility,
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  Future<void> pump(
    WidgetTester tester, {
    required RingingSession session,
    Widget? puzzleSlot,
    VoidCallback? onDismiss,
    VoidCallback? onSnooze,
    VoidCallback? onEscape,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: RingingScreen(
          session: session,
          onDismiss: onDismiss ?? () {},
          onSnooze: onSnooze ?? () {},
          onEscape: onEscape ?? () {},
          puzzleSlot: puzzleSlot,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('clock', () {
    testWidgets('renders the digits and the period apart', (tester) async {
      await pump(tester, session: _session());

      expect(find.text('7:00'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('shows the alarm label', (tester) async {
      await pump(tester, session: _session());

      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('an unlabelled alarm draws no empty label row', (tester) async {
      await pump(
        tester,
        session: _session(alarm: _alarm(label: '')),
      );

      expect(find.text(''), findsNothing);
    });
  });

  group('snooze and final alarm', () {
    testWidgets('snooze is offered when available', (tester) async {
      var snoozed = 0;
      await pump(
        tester,
        session: _session(),
        onSnooze: () => snoozed++,
      );

      await tester.tap(find.text('Snooze'));
      expect(snoozed, 1);
    });

    testWidgets('snooze is absent when unavailable', (tester) async {
      await pump(tester, session: _session(snoozeAvailable: false));

      expect(find.text('Snooze'), findsNothing);
    });

    testWidgets('the final alarm is named', (tester) async {
      await pump(
        tester,
        session: _session(snoozeAvailable: false, isFinalAlarm: true),
      );

      expect(find.text('This is the final alarm.'), findsOneWidget);
    });

    testWidgets('a non-final ring does not claim to be the last', (
      tester,
    ) async {
      await pump(tester, session: _session());

      expect(find.text('This is the final alarm.'), findsNothing);
    });

    testWidgets('a snoozed ring says so', (tester) async {
      await pump(
        tester,
        session: _session(occurrence: _occurrence(snoozeCount: 1)),
      );

      expect(find.text('Snoozed once'), findsOneWidget);
    });
  });

  group('dismiss methods', () {
    testWidgets('normalButton offers a plain stop', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        session: _session(),
        onDismiss: () => dismissed++,
      );

      await tester.tap(find.text('Stop alarm'));
      expect(dismissed, 1);
    });

    testWidgets('holdToDismiss offers a hold, not a tap', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        session: _session(
          alarm: _alarm(dismissMethod: DismissMethod.holdToDismiss),
        ),
        onDismiss: () => dismissed++,
      );

      expect(find.byType(HoldToActButton), findsOneWidget);
      expect(find.text('Hold to stop'), findsOneWidget);

      await tester.tap(find.byType(HoldToActButton));
      await tester.pump();
      expect(dismissed, 0, reason: 'a tap must not complete a hold');
    });

    testWidgets('a completed hold dismisses', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        session: _session(
          alarm: _alarm(dismissMethod: DismissMethod.holdToDismiss),
        ),
        onDismiss: () => dismissed++,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToActButton)),
      );
      await tester.pump(const Duration(milliseconds: 1400));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dismissed, 1);
    });

    testWidgets('an abandoned hold leaves the control reachable', (
      tester,
    ) async {
      var dismissed = 0;
      await pump(
        tester,
        session: _session(
          alarm: _alarm(dismissMethod: DismissMethod.holdToDismiss),
        ),
        onDismiss: () => dismissed++,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToActButton)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(dismissed, 0);
      expect(
        find.byType(HoldToActButton),
        findsOneWidget,
        reason: 'a failed hold never locks the user out',
      );
    });
  });

  group('the emergency escape', () {
    testWidgets('is present from the first frame of a puzzle alarm', (
      tester,
    ) async {
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
      );

      expect(find.text('Stop without solving'), findsOneWidget);
    });

    testWidgets('a puzzle alarm offers no direct stop', (tester) async {
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
      );

      expect(find.text('Stop alarm'), findsNothing);
    });

    testWidgets('it is still present when raised to prominent', (tester) async {
      await pump(
        tester,
        session: _session(
          alarm: _alarm(dismissMethod: DismissMethod.puzzle),
          escapeVisibility: PuzzleEscapeVisibility.prominent,
        ),
        puzzleSlot: const SizedBox(height: 120),
      );

      expect(find.text('Stop without solving'), findsOneWidget);
    });

    testWidgets('prominent promotes it to a filled button', (tester) async {
      await pump(
        tester,
        session: _session(
          alarm: _alarm(dismissMethod: DismissMethod.puzzle),
          escapeVisibility: PuzzleEscapeVisibility.prominent,
        ),
        puzzleSlot: const SizedBox(height: 120),
      );

      final buttons = tester
          .widgetList<CapyButton>(find.byType(CapyButton))
          .map((b) => b.label);
      expect(buttons, contains('Stop without solving'));
    });

    testWidgets('opens a confirmation rather than stopping at once', (
      tester,
    ) async {
      var escaped = 0;
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
        onEscape: () => escaped++,
      );

      await tester.tap(find.text('Stop without solving'));
      await tester.pumpAndSettle();

      expect(escaped, 0, reason: 'a reflex tap must not stop the alarm');
      expect(find.text('Stop without solving?'), findsOneWidget);
    });

    testWidgets('confirming it escapes', (tester) async {
      var escaped = 0;
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
        onEscape: () => escaped++,
      );

      await tester.tap(find.text('Stop without solving'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop the alarm'));
      await tester.pumpAndSettle();

      expect(escaped, 1);
    });

    testWidgets('cancelling returns to the puzzle', (tester) async {
      var escaped = 0;
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
        onEscape: () => escaped++,
      );

      await tester.tap(find.text('Stop without solving'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to the puzzle'));
      await tester.pumpAndSettle();

      expect(escaped, 0);
      expect(find.text('Stop without solving'), findsOneWidget);
    });
  });

  group('safety', () {
    testWidgets('nothing animates on the ringing surface', (tester) async {
      await pump(tester, session: _session());

      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'CLAUDE.md forbids animation on the ringing surface',
      );
    });

    testWidgets('the action controls clear the tap-target floor', (
      tester,
    ) async {
      await pump(tester, session: _session());

      for (final label in ['Snooze', 'Stop alarm']) {
        final size = tester.getSize(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(CapyButton),
          ),
        );
        expect(
          size.height,
          greaterThanOrEqualTo(44),
          reason: '$label is tapped by a half-asleep user',
        );
      }
    });

    testWidgets('the escape clears the tap-target floor too', (tester) async {
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
      );

      final size = tester.getSize(
        find
            .ancestor(
              of: find.text('Stop without solving'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('the clock is announced as one value', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, session: _session());

      expect(
        find.bySemanticsLabel('Alarm'),
        findsOneWidget,
        reason: 'the digits and period must not be read as two fragments',
      );
      handle.dispose();
    });

    testWidgets('the escape carries a semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        session: _session(alarm: _alarm(dismissMethod: DismissMethod.puzzle)),
        puzzleSlot: const SizedBox(height: 120),
      );

      expect(find.bySemanticsLabel('Stop without solving'), findsOneWidget);
      handle.dispose();
    });
  });

  group('self-review #2 probes', () {
    testWidgets('a 24-hour locale shows no period marker', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: RingingScreen(
            session: _session(),
            onDismiss: () {},
            onSnooze: () {},
            onEscape: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
    });

    test('the session describes itself without throwing', () {
      expect(_session().toString(), contains('a1'));
    });

    test('sessions with the same content are equal', () {
      expect(_session(), _session());
      expect(_session().hashCode, _session().hashCode);
    });

    test('a changed escape visibility makes them unequal', () {
      expect(
        _session(),
        isNot(
          _session(escapeVisibility: PuzzleEscapeVisibility.prominent),
        ),
      );
    });
  });
}
