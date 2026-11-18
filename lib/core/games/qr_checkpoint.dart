import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';

/// The code a user walks to each morning, kept as a salted digest: it cannot
/// be read back, only guessed, and the game needs equality alone.
@immutable
class QrCheckpoint {
  const QrCheckpoint({
    required this.digest,
    required this.salt,
    required this.savedAt,
  });

  factory QrCheckpoint.of(
    String code, {
    required DateTime savedAt,
    Random? random,
  }) {
    final source = random ?? Random.secure();
    final salt = [
      for (var i = 0; i < 16; i++)
        source.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    return QrCheckpoint(
      digest: digestOf('$salt\u0000$code'),
      salt: salt,
      savedAt: savedAt,
    );
  }

  factory QrCheckpoint.fromJson(Map<String, Object?> json) => QrCheckpoint(
    digest: json['digest']! as String,
    salt: json['salt']! as String,
    savedAt: DateTime.parse(json['savedAt']! as String),
  );

  final String digest;
  final String salt;
  final DateTime savedAt;

  bool matches(String code) => digestOf('$salt\u0000$code') == digest;

  Map<String, Object?> toJson() => {
    'digest': digest,
    'salt': salt,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };

  static const int _fnvOffset = (0xcbf29ce4 << 32) | 0x84222325;
  static const _fnvPrime = 0x100000001b3;

  /// FNV-1a, 64-bit, over the input's UTF-8 bytes, as 16 hex digits.
  static String digestOf(String input) {
    var hash = _fnvOffset;
    for (final byte in utf8.encode(input)) {
      hash = (hash ^ byte) * _fnvPrime;
    }
    String half(int bits) =>
        (bits & 0xffffffff).toRadixString(16).padLeft(8, '0');
    return half(hash >> 32) + half(hash);
  }

  @override
  bool operator ==(Object other) =>
      other is QrCheckpoint &&
      other.digest == digest &&
      other.salt == salt &&
      other.savedAt == savedAt;

  @override
  int get hashCode => Object.hash(digest, salt, savedAt);
}
