import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Work that must finish before the first frame: `intl` throws until its
/// symbol data is loaded, and every clock time goes through `DateFormat`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
}
