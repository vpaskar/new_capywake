import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:flutter/material.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SceneHeader(
      scene: SceneCrop.alarms,
      header: CapyHeader(),
      child: SizedBox.shrink(),
    );
  }
}
