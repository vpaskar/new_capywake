import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/core/games/qr_treasure_hunt.dart';
import 'package:flutter_test/flutter_test.dart';

final _checkpoint = QrCheckpoint.of(
  'MIRROR',
  savedAt: DateTime.utc(2026, 11, 18),
);

void main() {
  test('starts unfound, with nothing to say', () {
    final round = QrHuntRound.start();
    expect(round.isComplete, isFalse);
    expect(round.struggles, 0);
    expect(round.lastOutcome, isNull);
    expect(round.challenge.target, 1);
    expect(round.challenge.completed, 0);
    expect(round.challenge.requiresMotion, isFalse);
  });

  test('the checkpoint code wins', () {
    final round = QrHuntRound.start().scan('MIRROR', _checkpoint);
    expect(round.isComplete, isTrue);
    expect(round.challenge.isComplete, isTrue);
    expect(identical(round.scan('OTHER', _checkpoint), round), isTrue);
    expect(identical(round.cameraFailed(), round), isTrue);
  });

  test('a wrong code is one struggle until another code is seen (M1)', () {
    var round = QrHuntRound.start().scan('JAR', _checkpoint);
    expect(round.struggles, 1);
    expect(round.lastOutcome, QrHuntOutcome.wrongCode);
    round = round.scan('JAR', _checkpoint).scan('JAR', _checkpoint);
    expect(round.struggles, 1, reason: 'a held code is seen every frame');
    round = round.scan('BOOK', _checkpoint).scan('JAR', _checkpoint);
    expect(round.struggles, 2, reason: 'JAR was already counted this look');
    expect(round.challenge.struggleCount, 2);
  });

  test('a camera that will not start is a struggle each time (H3)', () {
    final round = QrHuntRound.start().cameraFailed().cameraFailed();
    expect(round.struggles, 2);
    expect(round.lastOutcome, QrHuntOutcome.cameraFailed);
    expect(round.isComplete, isFalse);
    expect(
      round.scan('JAR', _checkpoint).lastOutcome,
      QrHuntOutcome.wrongCode,
    );
  });

  test('without a checkpoint nothing can win', () {
    final round = QrHuntRound.start().scan('MIRROR', null);
    expect(round.isComplete, isFalse);
    expect(round.struggles, 1);
  });

  test('two wrong codes in view count once each, not per frame (R4)', () {
    var round = QrHuntRound.start();
    for (var frame = 0; frame < 20; frame++) {
      round = round.scan(frame.isEven ? 'EAN' : 'QR', _checkpoint);
    }
    expect(round.struggles, 2);
  });

  test('a new look lets a code count again', () {
    final round = QrHuntRound.start().scan('JAR', _checkpoint);
    expect(round.newLook().scan('JAR', _checkpoint).struggles, 2);
    final fresh = QrHuntRound.start();
    expect(identical(fresh.newLook(), fresh), isTrue);
    final won = fresh.scan('MIRROR', _checkpoint);
    expect(identical(won.newLook(), won), isTrue);
    expect(round.newLook().lastOutcome, QrHuntOutcome.wrongCode);
  });

  test('a camera failure forgets the last wrong code', () {
    final round = QrHuntRound.start()
        .scan('JAR', _checkpoint)
        .cameraFailed()
        .scan('JAR', _checkpoint);
    expect(round.struggles, 3);
  });
}
