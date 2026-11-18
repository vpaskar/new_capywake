import 'package:capywake/core/models/theme_mode_preference.dart';
import 'package:flutter/material.dart';

ThemeMode themeModeFor(ThemeModePreference preference) => switch (preference) {
  ThemeModePreference.system => ThemeMode.system,
  ThemeModePreference.light => ThemeMode.light,
  ThemeModePreference.dark => ThemeMode.dark,
};
