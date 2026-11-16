import 'package:timezone/timezone.dart' as tz;

/// Picks the `tz.Location` matching this device's clock, since `tz.local`
/// stays UTC until named. Matched by UTC offset at four instants a year.
abstract final class LocalLocationResolver {
  /// Tie-break order when several zones match. A tie is genuine — they are
  /// indistinguishable from the clock — so this only picks which name wins.
  static const preferredZones = <String>[
    'Europe/Berlin',
    'Europe/London',
    'Europe/Moscow',
    'Europe/Madrid',
    'Europe/Paris',
    'Europe/Rome',
    'Europe/Lisbon',
    'Europe/Istanbul',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Sao_Paulo',
    'Asia/Tokyo',
    'Asia/Riyadh',
    'Asia/Dubai',
    'UTC',
  ];

  /// Month offsets probed to fingerprint a zone, spread so a DST transition
  /// falls between two of them in either hemisphere.
  static const probeMonthOffsets = <int>[0, 3, 6, 9];

  /// The offsets [reference] reports at each probe instant, in minutes.
  static List<int> fingerprintOf(DateTime reference) {
    return [
      for (final months in probeMonthOffsets)
        _shiftMonths(reference, months).timeZoneOffset.inMinutes,
    ];
  }

  /// The offsets [location] would report at the same instants.
  static List<int> fingerprintOfLocation(
    tz.Location location,
    DateTime reference,
  ) {
    return [
      for (final months in probeMonthOffsets)
        tz.TZDateTime.from(
          _shiftMonths(reference, months),
          location,
        ).timeZoneOffset.inMinutes,
    ];
  }

  /// Every zone in the database reproducing [reference]'s offsets, sorted by
  /// [preferredZones] then alphabetically. Empty when none match.
  static List<String> candidatesFor(DateTime reference) {
    final target = fingerprintOf(reference);
    final matches = <String>[];
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      if (_sameFingerprint(
        fingerprintOfLocation(entry.value, reference),
        target,
      )) {
        matches.add(entry.key);
      }
    }
    matches.sort(_byPreferenceThenName);
    return matches;
  }

  /// The best zone for a clock behaving like [reference], or null when none
  /// matches — a real answer, since arming in a wrong zone silently is worse.
  static tz.Location? resolve(DateTime reference) {
    final names = candidatesFor(reference);
    if (names.isEmpty) return null;
    return tz.timeZoneDatabase.locations[names.first];
  }

  static int _byPreferenceThenName(String a, String b) {
    final ia = preferredZones.indexOf(a);
    final ib = preferredZones.indexOf(b);
    if (ia != ib) {
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    }
    return a.compareTo(b);
  }

  static bool _sameFingerprint(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// [from] advanced by [months], clamping the day so no month overflows.
  static DateTime _shiftMonths(DateTime from, int months) {
    final total = from.month - 1 + months;
    final year = from.year + total ~/ 12;
    final month = total % 12 + 1;
    final day = from.day <= 28 ? from.day : 28;
    return DateTime(year, month, day, from.hour, from.minute);
  }
}
