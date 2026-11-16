import 'package:capywake/design/capy_header.dart';
import 'package:capywake/design/scene_header.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SceneHeader(
      scene: SceneCrop.home,
      header: CapyHeader(),
      child: SizedBox.shrink(),
    );
  }
}
