// No-fake-numbers gate for Stats: dart run tool/check_no_fake_stats.dart
// [--path <dir>] [--quiet]. Blind spots are asserted in its test.

import 'dart:io';

/// All of `lib/features/`, not just Stats: the rule is about any screen
/// stating a number it does not have, and the wider scan was already clean.
const defaultScanPath = 'lib/features';

/// Digits in these are geometry or indices, not claims about data.
final _allowedContext = RegExp(
  r'(Duration\(|EdgeInsets|SizedBox|BorderRadius|Radius\.|Offset\(|Size\('
  '|fontSize|height:|width:|size:|flex:|maxLines|alpha|opacity|elevation'
  r'|blurRadius|spreadRadius|strokeWidth|\bindex\b|length|\.only\(|padding'
  r'|\bconst [A-Z]|=> *[0-9]|windowDays|CapySpacing|CapyRadius|CapyIconSize)',
);

/// A bare number handed to Text: `Text(7)`, `Text(7.5)`. An identifier that
/// merely contains a digit, or a localized call taking one, is not a claim.
final _textLiteral = RegExp(r'\bText\(\s*-?\d+(\.\d+)?\s*[,)]');

final _valueArgument = RegExp(
  r'''\b(value|label|title|subtitle)\s*:\s*-?\d+(\.\d+)?\s*[,)]''',
);

/// `%` is a non-word character and so is the closing quote, so a trailing
/// `\b` can never match after it; `(?![a-z])` is the boundary that works.
final _figureInString = RegExp(
  r'''['"][^'"]*\d+\s*(%|h|m|min|hrs?|hours?|mins?|days?)(?![a-z])[^'"]*['"]''',
  caseSensitive: false,
);

final _interpolatedDigit = RegExp(r'''['"][^'"]*\$\{?\d''');

class Finding {
  Finding(this.file, this.line, this.text, this.why);

  final String file;
  final int line;
  final String text;
  final String why;

  @override
  String toString() => '  $file:$line  $why\n    ${text.trim()}';
}

List<Finding> scan(String source, String path) {
  final findings = <Finding>[];
  final lines = source.split('\n');
  var inBlockComment = false;

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final line = raw.trim();

    if (inBlockComment) {
      if (line.contains('*/')) inBlockComment = false;
      continue;
    }
    if (line.startsWith('/*')) {
      if (!line.contains('*/')) inBlockComment = true;
      continue;
    }
    if (line.startsWith('//') || line.isEmpty) continue;
    if (_allowedContext.hasMatch(raw)) continue;

    if (_textLiteral.hasMatch(raw)) {
      findings.add(Finding(path, i + 1, raw, 'numeric literal inside Text()'));
    } else if (_valueArgument.hasMatch(raw)) {
      findings.add(Finding(path, i + 1, raw, 'numeric literal as a value'));
    } else if (_figureInString.hasMatch(raw)) {
      findings.add(Finding(path, i + 1, raw, 'hardcoded figure in a string'));
    } else if (_interpolatedDigit.hasMatch(raw)) {
      findings.add(
        Finding(path, i + 1, raw, 'digit interpolated into a string'),
      );
    }
  }
  return findings;
}

void main(List<String> args) {
  var scanPath = defaultScanPath;
  var quiet = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--path':
        scanPath = args[++i];
      case '--quiet':
        quiet = true;
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(2);
    }
  }

  final dir = Directory(scanPath);
  if (!dir.existsSync()) {
    stderr.writeln('Scan path not found: $scanPath');
    exit(2);
  }

  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final all = <Finding>[];
  for (final file in files) {
    final findings = scan(file.readAsStringSync(), file.path);
    all.addAll(findings);
    if (!quiet) {
      final name = file.path;
      stdout.writeln(findings.isEmpty ? 'OK   $name' : 'FAIL $name');
    }
  }

  if (all.isNotEmpty) {
    stderr.writeln('\n${all.length} fabricated number(s) in $scanPath:');
    for (final f in all) {
      stderr.writeln(f);
    }
    stderr.writeln(
      '\nStats renders measured data or nothing. A number here states '
      'something about a user who may have no data at all.',
    );
    exit(1);
  }

  stdout.writeln('\nNo fabricated numbers in ${files.length} file(s).');
}
