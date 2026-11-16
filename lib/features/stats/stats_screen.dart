import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SceneHeader(
      scene: SceneCrop.stats,
      // Phase 08 measures this from `05_STATS.png`; Home's 188.4 until then.
      bandHeight: 188.4,
      header: CapyHeader(),
      child: SizedBox.shrink(),
    );
  }
}
