import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SceneHeader(
      scene: SceneCrop.stats,
      header: CapyHeader(),
      child: SizedBox.shrink(),
    );
  }
}
