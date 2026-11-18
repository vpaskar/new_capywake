import 'package:capywake/features/games/game_header.dart';
import 'package:flutter_test/flutter_test.dart';

import '_pump.dart';

void main() {
  testWidgets('progress is a live region, so every step is announced', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(
      tester,
      const GameHeader(title: 'T', instruction: 'I', done: 2, total: 5),
    );
    final progress = find.bySemanticsLabel(RegExp('2'));
    expect(progress, findsOneWidget);
    expect(
      tester.getSemantics(progress).flagsCollection.isLiveRegion,
      isTrue,
    );
    handle.dispose();
  });
}
