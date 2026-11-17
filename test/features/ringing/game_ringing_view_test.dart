import 'package:capywake/core/games/game_challenge.dart';
import 'package:capywake/core/models/models.dart';
import 'package:capywake/core/puzzle/puzzle_settings.dart';
import 'package:capywake/features/ringing/game_ringing_view.dart';
import 'package:capywake/features/ringing/ringing_screen.dart';
import 'package:capywake/features/ringing/ringing_session.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Test-only reference conformer — the foundation's "hello world", never a
/// product. A counter game: each tap advances; a long-press is a struggle.
class _ReferenceGameView extends GameRingingView {
  const _ReferenceGameView({
    required super.onProgress,
    required super.onCompleted,
    required super.reduceMotion,
    required this.challenge,
  });

  final GameChallenge challenge;

  @override
  State<_ReferenceGameView> createState() => _ReferenceGameViewState();
}

class _ReferenceGameViewState extends State<_ReferenceGameView> {
  late GameChallenge _challenge = widget.challenge;

  void _advance() {
    _challenge = GameChallenge.touch(
      target: _challenge.target,
      completed: _challenge.completed + 1,
      struggleCount: _challenge.struggleCount,
    );
    widget.onProgress(_challenge);
    if (_challenge.isComplete) widget.onCompleted();
  }

  void _struggle() {
    _challenge = GameChallenge.touch(
      target: _challenge.target,
      completed: _challenge.completed,
      struggleCount: _challenge.struggleCount + 1,
    );
    setState(() {});
    widget.onProgress(_challenge);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('catches: ${_challenge.completed}'),
        ElevatedButton(onPressed: _advance, child: const Text('catch')),
        ElevatedButton(onPressed: _struggle, child: const Text('miss')),
      ],
    );
  }
}

Alarm _alarm() {
  final t = DateTime.utc(2026, 5, 21, 8);
  return Alarm(
    id: 'a1',
    label: 'Morning',
    enabled: true,
    targetTimeMinutes: 7 * 60,
    repeatWeekdays: const {},
    wakeMode: WakeMode.standard,
    wakeWindowStartMinutesBefore: 0,
    soundId: 'gentle',
    vibrationEnabled: true,
    snoozeEnabled: true,
    snoozeDurationMinutes: 9,
    maxSnoozes: 5,
    dismissMethod: DismissMethod.puzzle,
    dismissChallengeDifficulty: null,
    confirmationEnabled: false,
    createdAt: t,
    updatedAt: t,
  );
}

RingingSession _session({
  PuzzleEscapeVisibility escapeVisibility = PuzzleEscapeVisibility.available,
}) => RingingSession(
  alarm: _alarm(),
  occurrence: AlarmOccurrence(
    id: 'o1',
    alarmId: 'a1',
    scheduledAt: DateTime.utc(2026, 5, 21, 5),
    softStartAt: null,
    status: AlarmStatus.triggered,
    triggeredAt: DateTime.utc(2026, 5, 21, 5),
    dismissedAt: null,
    snoozeCount: 0,
    note: '',
  ),
  snoozeAvailable: false,
  isFinalAlarm: false,
  escapeVisibility: escapeVisibility,
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  Future<void> pumpGame(
    WidgetTester tester, {
    required GameChallenge challenge,
    required PuzzleEscapeVisibility escapeVisibility,
    required ValueChanged<GameChallenge> onProgress,
    required VoidCallback onDismiss,
    required VoidCallback onEscape,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: RingingScreen(
          session: _session(escapeVisibility: escapeVisibility),
          onDismiss: onDismiss,
          onSnooze: () {},
          onEscape: onEscape,
          puzzleSlot: _ReferenceGameView(
            challenge: challenge,
            reduceMotion: reduceMotion,
            onProgress: onProgress,
            onCompleted: onDismiss,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a game in the ringing slot', () {
    testWidgets('dismisses the alarm when its goal is reached', (tester) async {
      var dismissed = 0;
      await pumpGame(
        tester,
        challenge: const GameChallenge.touch(target: 2, completed: 0),
        escapeVisibility: PuzzleEscapeVisibility.available,
        onProgress: (_) {},
        onDismiss: () => dismissed++,
        onEscape: () {},
      );

      await tester.tap(find.text('catch'));
      await tester.pump();
      expect(dismissed, 0, reason: 'one catch of two is not the goal');

      await tester.tap(find.text('catch'));
      await tester.pump();
      expect(dismissed, 1, reason: 'the second catch reaches the goal');
    });

    testWidgets('reports progress so the host can raise the escape', (
      tester,
    ) async {
      final struggles = <int>[];
      await pumpGame(
        tester,
        challenge: const GameChallenge.touch(target: 5, completed: 0),
        escapeVisibility: PuzzleEscapeVisibility.available,
        onProgress: (c) => struggles.add(c.struggleCount),
        onDismiss: () {},
        onEscape: () {},
      );

      await tester.tap(find.text('miss'));
      await tester.pump();
      await tester.tap(find.text('miss'));
      await tester.pump();

      expect(struggles, [1, 2], reason: 'the host hears every struggle');
    });

    testWidgets('keeps the escape reachable while a game is unsolved', (
      tester,
    ) async {
      var escaped = 0;
      await pumpGame(
        tester,
        challenge: const GameChallenge.touch(target: 5, completed: 0),
        escapeVisibility: PuzzleEscapeVisibility.available,
        onProgress: (_) {},
        onDismiss: () {},
        onEscape: () => escaped++,
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final escape = find.text(l10n.puzzleEscapeAction);
      expect(escape, findsOneWidget, reason: 'a game must not hide the escape');

      await tester.tap(escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.puzzleEscapeConfirmAction));
      await tester.pumpAndSettle();
      expect(
        escaped,
        1,
        reason: 'the escape the game does not own still works',
      );
    });

    testWidgets('the escape is prominent when the session says so', (
      tester,
    ) async {
      await pumpGame(
        tester,
        challenge: const GameChallenge.touch(target: 5, completed: 0),
        escapeVisibility: PuzzleEscapeVisibility.prominent,
        onProgress: (_) {},
        onDismiss: () {},
        onEscape: () {},
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.puzzleEscapeAction), findsOneWidget);
    });
  });
}
