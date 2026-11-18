import 'dart:math';

import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = DateTime.utc(2026, 11, 18, 7);

void main() {
  test('the digest is FNV-1a 64 (published test vectors)', () {
    expect(QrCheckpoint.digestOf(''), 'cbf29ce484222325');
    expect(QrCheckpoint.digestOf('a'), 'af63dc4c8601ec8c');
    expect(QrCheckpoint.digestOf('foobar'), '85944171f73967e8');
  });

  test('matches its own code and nothing else', () {
    final checkpoint = QrCheckpoint.of('BATHROOM-MIRROR', savedAt: _at);
    expect(checkpoint.matches('BATHROOM-MIRROR'), isTrue);
    expect(checkpoint.matches('bathroom-mirror'), isFalse);
    expect(checkpoint.matches('BATHROOM-MIRROR '), isFalse);
    expect(checkpoint.matches(''), isFalse);
  });

  test('never keeps the code itself (a QR can carry a password)', () {
    const secret = 'WIFI:S:home;T:WPA;P:hunter2-secret;;';
    final checkpoint = QrCheckpoint.of(secret, savedAt: _at);
    expect(checkpoint.toJson().toString(), isNot(contains('hunter2')));
    expect(
      checkpoint.toJson().keys,
      unorderedEquals(['digest', 'salt', 'savedAt']),
    );
    expect(checkpoint.digest, hasLength(16));
  });

  test('salted per checkpoint: one code, two saves, two digests (R7)', () {
    final a = QrCheckpoint.of('MIRROR', savedAt: _at);
    final b = QrCheckpoint.of('MIRROR', savedAt: _at);
    expect(a.salt, hasLength(32));
    expect(a.salt, isNot(b.salt));
    expect(a.digest, isNot(b.digest));
    expect(a.digest, isNot(QrCheckpoint.digestOf('MIRROR')));
    expect(a.matches('MIRROR') && b.matches('MIRROR'), isTrue);
  });

  test('a seeded random gives a repeatable salt', () {
    expect(
      QrCheckpoint.of('X', savedAt: _at, random: Random(1)).salt,
      QrCheckpoint.of('X', savedAt: _at, random: Random(1)).salt,
    );
  });

  test('survives a JSON round trip, non-ASCII included', () {
    final checkpoint = QrCheckpoint.of('кофе ☕', savedAt: _at);
    final back = QrCheckpoint.fromJson(checkpoint.toJson());
    expect(back, checkpoint);
    expect(back.hashCode, checkpoint.hashCode);
    expect(back.matches('кофе ☕'), isTrue);
    expect(back, isNot(QrCheckpoint.of('tea', savedAt: _at)));
  });
}
