import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_no_fake_stats.dart';

/// `CLAUDE.md` documented this gate from Phase 00 while the file did not
/// exist; Phase 07's full-project review found that and Phase 08 writes it.
void main() {
  group('catches a fabricated number', () {
    test('a bare number handed to Text()', () {
      final found = scan('Text(7),', 'fake.dart');
      expect(found, hasLength(1));
      expect(found.single.why, contains('Text()'));
      expect(found.single.line, 1);
    });

    test('a hardcoded figure inside Text()', () {
      expect(scan("Text('7 h 32 m'),", 'fake.dart'), hasLength(1));
    });

    test('a hardcoded percentage', () {
      expect(scan("const average = 'Avg. 94%';", 'fake.dart'), hasLength(1));
    });

    test('a hardcoded duration figure', () {
      expect(scan("label: '52 h 44 m',", 'fake.dart'), hasLength(1));
    });

    test('a digit interpolated into a string', () {
      expect(scan(r"final s = 'streak $6 days';", 'f.dart'), hasLength(1));
    });

    test('reports the line number so the offender is findable', () {
      final found = scan("final a = 1;\nfinal b = 2;\nText('8 h'),", 'f.dart');
      expect(found.single.line, 3);
    });
  });

  group('does not flag a number that is not a claim about data', () {
    test('geometry constants', () {
      expect(scan('static const heroBandHeight = 111.5;', 'f.dart'), isEmpty);
      expect(scan('const SizedBox(height: 12),', 'f.dart'), isEmpty);
      expect(scan('padding: const EdgeInsets.all(16),', 'f.dart'), isEmpty);
    });

    test('a window length, which describes the query not the data', () {
      expect(scan('windowDays: 14,', 'f.dart'), isEmpty);
    });

    test('a value read from a summary', () {
      expect(scan('Text(summary.onTimeCount.toString()),', 'f.dart'), isEmpty);
    });

    test('a localized call that takes a number', () {
      expect(scan('Text(l10n.historyWindowLabel(14)),', 'f.dart'), isEmpty);
    });

    test('an identifier that happens to contain a digit', () {
      expect(scan('Text(context.pad1),', 'f.dart'), isEmpty);
    });

    test('a comment, including one quoting the mockup', () {
      expect(scan("// The mockup draws '7 h 32 m' here.", 'f.dart'), isEmpty);
      expect(scan('/// 215.4 - 103.9 on the mockup.', 'f.dart'), isEmpty);
    });

    test('a block comment', () {
      expect(scan("/*\nText('7 h 32 m')\n*/", 'f.dart'), isEmpty);
    });
  });

  group('the blind spots, asserted so they are documented not assumed', () {
    test('a ?? fallback supplying a literal is NOT caught', () {
      expect(
        scan('Text(summary.typicalWakeMinutes ?? 450),', 'f.dart'),
        isEmpty,
        reason:
            'A syntactic scan sees an int in an expression, not a claim. '
            'This is the shape that would ship; the widget test covers it.',
      );
    });

    test('arithmetic over constants is NOT caught', () {
      expect(scan('final m = 7 * 60 + 32;', 'f.dart'), isEmpty);
    });

    test('a provider default reaching a tile is NOT caught', () {
      expect(
        scan('Text(HistorySummary.empty.onTimeCount), ', 'f.dart'),
        isEmpty,
      );
    });
  });
}
