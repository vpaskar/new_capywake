import 'package:capywake/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// One selectable alarm tone.
///
/// [assetPath] is what reaches `package:alarm` as `assetAudioPath`. A null path
/// is not a missing file — see [AlarmSoundCatalog.deviceDefault].
@immutable
class AlarmSound {
  const AlarmSound({
    required this.id,
    required this.assetPath,
    this.category = AlarmSoundCategory.gentle,
  });

  /// Stable identifier persisted on `Alarm.soundId` and
  /// `UserSettings.defaultSoundId`. Never shown to the user.
  final String id;

  /// Bundled asset to play, or null to let the platform choose.
  ///
  /// **Must start with `assets/`** when non-null. iOS branches on that prefix
  /// to decide between a bundled asset and a path inside the app's Documents
  /// directory; anything else is treated as the latter, fails to load, and logs
  /// rather than throwing — so the alarm rings silently, on device only.
  final String? assetPath;

  final AlarmSoundCategory category;

  /// This sound's display name in the current locale.
  ///
  /// The names live in ARB so translators control them; the mapping lives here
  /// so no screen has to own a copy of it.
  String label(AppLocalizations l10n) => switch (id) {
    AlarmSoundCatalog.chimesId => l10n.alarmSoundChimes,
    AlarmSoundCatalog.morningId => l10n.alarmSoundMorning,
    AlarmSoundCatalog.gentleId => l10n.alarmSoundGentle,
    'soft_mallets' => l10n.alarmSoundSoftMallets,
    'first_light' => l10n.alarmSoundFirstLight,
    'glass_drops' => l10n.alarmSoundGlassDrops,
    'wooden_knocks' => l10n.alarmSoundWoodenKnocks,
    'bamboo_pulse' => l10n.alarmSoundBambooPulse,
    'syncopated_marimba' => l10n.alarmSoundSyncopatedMarimba,
    'mechanical_bell' => l10n.alarmSoundMechanicalBell,
    'station_signal' => l10n.alarmSoundStationSignal,
    'three_tone_beacon' => l10n.alarmSoundThreeToneBeacon,
    _ => l10n.alarmSoundDefault,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSound && other.id == id && other.assetPath == assetPath;

  @override
  int get hashCode => Object.hash(id, assetPath);

  @override
  String toString() => 'AlarmSound($id, ${assetPath ?? 'device default'})';
}

enum AlarmSoundCategory { platform, gentle, rhythmic, firm }

/// The one list of built-in alarm tones.
///
/// Every surface that offers a sound — the alarm form's picker, the default in
/// Settings — and the one place that plays it — `PlatformAlarmEngine` — reads
/// this catalogue. Before it existed the id list, the fallback rule and the
/// label `switch` were written out twice in two screens, and the engine read
/// none of them: the picker persisted a choice that nothing consumed.
///
/// Flutter-free apart from the generated localisations, which are a plain value
/// class — the arrangement `AlarmRepeatSummary` and `ReliabilityCopyService`
/// already use, and for the same reason: the wording belongs with the rule that
/// chooses it.
abstract final class AlarmSoundCatalog {
  /// Id of the platform-chosen sound. Also the value [resolve] falls back to.
  static const iosDefaultPath = 'assets/sounds/chimes.wav';

  static const String defaultId = 'default';

  /// Id of the descending bell figure.
  static const String chimesId = 'chimes';

  /// Id of the ascending mallet figure.
  static const String morningId = 'morning';

  /// Id of the low, slow swell.
  static const String gentleId = 'gentle';

  /// Whatever the phone would play on its own.
  ///
  /// **The null [AlarmSound.assetPath] is the feature, not an omission.** It is
  /// what makes Android play the device's own alarm sound and iOS the tone
  /// bundled inside `package:alarm`. Pointing this at a CapyWake file would
  /// silently override an alarm sound the user may have picked deliberately in
  /// their OS settings, and it would cost bundle size for the privilege.
  static const AlarmSound deviceDefault = AlarmSound(
    id: defaultId,
    assetPath: null,
    category: AlarmSoundCategory.platform,
  );

  /// The catalogue, in the order the pickers present it.
  ///
  /// [deviceDefault] leads because it is the initial value: an alarm created
  /// before the user touches the picker carries `UserSettings.initial`'s empty
  /// `defaultSoundId`, which [resolve] maps here.
  static const List<AlarmSound> sounds = [
    deviceDefault,
    AlarmSound(id: chimesId, assetPath: 'assets/sounds/chimes.wav'),
    AlarmSound(
      id: morningId,
      assetPath: 'assets/sounds/morning.wav',
      category: AlarmSoundCategory.rhythmic,
    ),
    AlarmSound(id: gentleId, assetPath: 'assets/sounds/gentle.wav'),
    AlarmSound(
      id: 'soft_mallets',
      assetPath: 'assets/sounds/soft_mallets.wav',
    ),
    AlarmSound(
      id: 'first_light',
      assetPath: 'assets/sounds/first_light.wav',
    ),
    AlarmSound(
      id: 'glass_drops',
      assetPath: 'assets/sounds/glass_drops.wav',
    ),
    AlarmSound(
      id: 'wooden_knocks',
      assetPath: 'assets/sounds/wooden_knocks.wav',
      category: AlarmSoundCategory.rhythmic,
    ),
    AlarmSound(
      id: 'bamboo_pulse',
      assetPath: 'assets/sounds/bamboo_pulse.wav',
      category: AlarmSoundCategory.rhythmic,
    ),
    AlarmSound(
      id: 'syncopated_marimba',
      assetPath: 'assets/sounds/syncopated_marimba.wav',
      category: AlarmSoundCategory.rhythmic,
    ),
    AlarmSound(
      id: 'mechanical_bell',
      assetPath: 'assets/sounds/mechanical_bell.wav',
      category: AlarmSoundCategory.firm,
    ),
    AlarmSound(
      id: 'station_signal',
      assetPath: 'assets/sounds/station_signal.wav',
      category: AlarmSoundCategory.firm,
    ),
    AlarmSound(
      id: 'three_tone_beacon',
      assetPath: 'assets/sounds/three_tone_beacon.wav',
      category: AlarmSoundCategory.firm,
    ),
  ];

  /// The sound stored under [id], or [deviceDefault] if there is no such sound.
  ///
  /// Unknown ids are ordinary rather than exceptional: the empty string is what
  /// `UserSettings.initial.defaultSoundId` holds, and a tone retired in a later
  /// version leaves its id behind on alarms already saved. Both should keep
  /// ringing, so both fall back rather than throw.
  static AlarmSound resolve(String id) {
    for (final sound in sounds) {
      if (sound.id == id) return sound;
    }
    return deviceDefault;
  }
}
