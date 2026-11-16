import 'package:capywake/app/app.dart';
import 'package:capywake/app/bootstrap.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const CapyWakeApp());
}
