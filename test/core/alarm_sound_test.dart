import 'dart:io';

import 'package:capywake/core/alarm_sound.dart';
import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlarmSoundCatalog.resolve', () {
    test('returns each known sound by id', () {
      for (final sound in AlarmSoundCatalog.sounds) {
        expect(AlarmSoundCatalog.resolve(sound.id), sound);
      }
    });

    test('falls back to the device default for the empty id', () {
      // `UserSettings.initial.defaultSoundId` is the empty string, so this is
      // the id every alarm carries until someone opens the picker.
      expect(AlarmSoundCatalog.resolve(''), AlarmSoundCatalog.deviceDefault);
    });

    test('falls back to the device default for an unknown id', () {
      // A tone retired in a later version leaves its id behind on alarms
      // already saved. Those alarms keep ringing.
      expect(
        AlarmSoundCatalog.resolve('retired-in-v2'),
        AlarmSoundCatalog.deviceDefault,
      );
    });

    test('is case-sensitive — ids are stored values, not user input', () {
      expect(
        AlarmSoundCatalog.resolve('Chimes'),
        AlarmSoundCatalog.deviceDefault,
      );
    });
  });

  group('catalogue shape', () {
    test('offers twelve originals and the platform default first', () {
      expect(AlarmSoundCatalog.sounds.first, AlarmSoundCatalog.deviceDefault);
      expect(
        AlarmSoundCatalog.sounds.where((sound) => sound.assetPath != null),
        hasLength(12),
      );
    });

    test('ids are unique', () {
      final ids = AlarmSoundCatalog.sounds.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the device default deliberately bundles no file', () {
      // Not an omission: a null path is what makes Android play the phone's own
      // alarm sound and iOS the tone inside `package:alarm`. Pointing it at a
      // CapyWake file would override a sound the user may have chosen in their
      // OS settings.
      expect(AlarmSoundCatalog.deviceDefault.assetPath, isNull);
    });

    test('every other sound bundles a file', () {
      final withoutAsset = AlarmSoundCatalog.sounds
          .where((s) => s.id != AlarmSoundCatalog.defaultId)
          .where((s) => s.assetPath == null);
      expect(withoutAsset, isEmpty);
    });
  });

  group('bundled assets', () {
    /// Non-null asset paths, which is every entry but the device default.
    Iterable<String> bundledPaths() =>
        AlarmSoundCatalog.sounds.map((s) => s.assetPath).whereType<String>();

    test('every asset path starts with assets/', () {
      // iOS branches on this prefix to tell a bundled asset from a path inside
      // the app's Documents directory. Anything else fails to load and logs
      // rather than throwing — the alarm rings silently, on device only. A
      // later rename cannot quietly break that.
      for (final path in bundledPaths()) {
        expect(
          path,
          startsWith('assets/'),
          reason: '$path would be read as a Documents path on iOS',
        );
      }
    });

    test('every asset exists on disk', () {
      for (final path in bundledPaths()) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is in the catalogue but not in the repository',
        );
      }
    });

    test('every asset is declared in pubspec.yaml', () {
      // A catalogue entry that is not bundled fails silently on device — which
      // is precisely the class of bug this whole area exists to close.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declared = pubspec
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.startsWith('- assets/'))
          .map((line) => line.substring(2).trim())
          .toList();

      for (final path in bundledPaths()) {
        final covered = declared.any(
          // A trailing slash declares a whole directory, which covers
          // everything inside it.
          (entry) =>
              entry == path || (entry.endsWith('/') && path.startsWith(entry)),
        );
        expect(
          covered,
          isTrue,
          reason: '$path is not covered by any pubspec asset declaration',
        );
      }
    });

    test('every asset is a non-trivial file', () {
      // Guards against a truncated or placeholder write: silence would pass
      // every other check here.
      for (final path in bundledPaths()) {
        expect(
          File(path).lengthSync(),
          greaterThan(1024),
          reason: '$path looks empty or truncated',
        );
      }
    });
  });

  group('labels', () {
    late AppLocalizations en;

    setUp(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('each sound reads its own localised name', () {
      expect(
        AlarmSoundCatalog.resolve('chimes').label(en),
        en.alarmSoundChimes,
      );
      expect(
        AlarmSoundCatalog.resolve('morning').label(en),
        en.alarmSoundMorning,
      );
      expect(
        AlarmSoundCatalog.resolve('gentle').label(en),
        en.alarmSoundGentle,
      );
      expect(
        AlarmSoundCatalog.deviceDefault.label(en),
        en.alarmSoundDefault,
      );
    });

    test('an unknown id labels as the device default', () {
      const stranger = AlarmSound(id: 'nope', assetPath: null);
      expect(stranger.label(en), en.alarmSoundDefault);
    });

    test('the default label names what will play, not "Default"', () {
      // "Default" told the user nothing about what they would hear. The option
      // bundles no file, so the label has to say whose sound it is.
      expect(en.alarmSoundDefault, isNot(equalsIgnoringCase('default')));
    });

    test('every locale gives every sound a non-empty, distinct name', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        final labels = AlarmSoundCatalog.sounds
            .map((s) => s.label(l10n))
            .toList();
        for (final label in labels) {
          expect(
            label.trim(),
            isNotEmpty,
            reason: 'empty sound name in ${locale.languageCode}',
          );
        }
        expect(
          labels.toSet(),
          hasLength(labels.length),
          reason: 'duplicate sound names in ${locale.languageCode}: $labels',
        );
      }
    });
  });

  group('AlarmSound value semantics', () {
    test('equal by id and asset path', () {
      const a = AlarmSound(id: 'chimes', assetPath: 'assets/sounds/chimes.wav');
      const b = AlarmSound(id: 'chimes', assetPath: 'assets/sounds/chimes.wav');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(identical(a, a), isTrue);
    });

    test('differs on id', () {
      const a = AlarmSound(id: 'chimes', assetPath: 'assets/sounds/x.wav');
      const b = AlarmSound(id: 'gentle', assetPath: 'assets/sounds/x.wav');
      expect(a, isNot(b));
    });

    test('differs on asset path', () {
      const a = AlarmSound(id: 'chimes', assetPath: 'assets/sounds/a.wav');
      const b = AlarmSound(id: 'chimes', assetPath: 'assets/sounds/b.wav');
      expect(a, isNot(b));
    });

    test('is not equal to another type', () {
      expect(AlarmSoundCatalog.deviceDefault, isNot(equals('default')));
    });

    test('toString names the sound and says when there is no file', () {
      expect(AlarmSoundCatalog.deviceDefault.toString(), contains('default'));
      expect(
        AlarmSoundCatalog.deviceDefault.toString(),
        contains('device default'),
      );
      expect(
        AlarmSoundCatalog.resolve('chimes').toString(),
        contains('assets/sounds/chimes.wav'),
      );
    });
  });
}
