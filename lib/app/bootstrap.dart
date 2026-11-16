import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Loads the data `intl` and `package:timezone` both throw without, before any
/// clock time is formatted or any alarm is armed.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  tzdata.initializeTimeZones();
}
