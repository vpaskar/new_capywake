import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _locales = ['en', 'de', 'ru', 'es', 'tr', 'fr', 'it', 'pt', 'ar', 'ja'];

/// The device-wide promise each locale made before the Android scanner was
/// found sending Google diagnostics. Only pictures can be promised.
const _retiredCameraClaims = {
  'en': 'nothing leaves your phone',
  'de': 'nichts verlässt dein Handy',
  'ru': 'Ничего не записывается и не покидает',
  'es': 'nada sale de tu teléfono',
  'tr': 'Hiçbir şey kaydedilmez',
  'fr': 'rien ne quitte ton téléphone',
  'it': 'nulla lascia il telefono',
  'pt': 'nada sai do seu telefone',
  'ar': 'ولا يغادر أي شيء هاتفك',
  'ja': 'データはスマホの外に出ません',
};

const _retiredStepClaims = {
  'en': 'nothing leaves your phone',
  'de': 'nichts verlässt dein Handy',
  'ru': 'ничего не покидает телефон',
  'es': 'nada sale de tu teléfono',
  'tr': 'hiçbir şey telefonundan çıkmaz',
  'fr': 'rien ne quitte ton téléphone',
  'it': 'nulla lascia il telefono',
  'pt': 'nada sai do telefone',
  'ar': 'ولا يغادر أي شيء هاتفك',
  'ja': 'データはスマホの外に出ません',
};

String _string(String locale, String key) {
  final arb =
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  return arb[key] as String;
}

String _camera(String locale) => _string(locale, 'cameraAccessBody');

void main() {
  for (final locale in _locales) {
    test('$locale camera rationale promises only pictures', () {
      expect(
        _camera(locale).toLowerCase(),
        isNot(contains(_retiredCameraClaims[locale]!.toLowerCase())),
      );
    });
  }

  for (final locale in _locales) {
    test('$locale step rationale promises only steps', () {
      expect(
        _string(locale, 'stepAccessBody').toLowerCase(),
        isNot(contains(_retiredStepClaims[locale]!.toLowerCase())),
      );
    });
  }

  test('English names what stays on the phone', () {
    expect(_camera('en'), contains('no picture leaves your phone'));
  });
}
