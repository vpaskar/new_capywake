import 'package:capywake/core/games/qr_checkpoint.dart';
import 'package:capywake/data/database/app_database.dart';
import 'package:capywake/data/repositories/capy_wake_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CapyWakeRepository repo;
  final at = DateTime.utc(2026, 11, 18, 7);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CapyWakeRepository(db);
  });
  tearDown(() => db.close());

  test('no checkpoint until one is saved', () async {
    expect(await repo.getQrCheckpoint(), isNull);
  });

  test('saves, replaces and watches the one checkpoint', () async {
    final first = QrCheckpoint.of('MIRROR', savedAt: at);
    final second = QrCheckpoint.of('JAR', savedAt: at);
    expect(await repo.watchQrCheckpoint().first, isNull);
    await repo.saveQrCheckpoint(first);
    await repo.saveQrCheckpoint(second);
    expect(await repo.getQrCheckpoint(), second);
    expect(await repo.watchQrCheckpoint().first, second);
  });

  test('the stored row holds a digest, never the code (H4)', () async {
    const secret = 'WIFI:S:home;T:WPA;P:hunter2-secret;;';
    await repo.saveQrCheckpoint(QrCheckpoint.of(secret, savedAt: at));
    final rows = await db.select(db.singletons).get();
    final row = rows.singleWhere(
      (r) => r.singletonKey == AppDatabase.qrCheckpointSingletonKey,
    );
    expect(row.valueJson, isNot(contains('hunter2')));
    expect((await repo.getQrCheckpoint())!.matches(secret), isTrue);
  });
}
