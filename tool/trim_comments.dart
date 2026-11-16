import 'dart:convert';
import 'dart:io';

/// Caps comment blocks at this many lines. `--fix` rewrites, bare reports.
const maxBlockLines = 2;

/// Content budget, because two long lines can carry more prose than five short
/// ones and a line cap alone misses that.
const maxBlockChars = 300;

final _scanned = ['lib', 'test', 'tool'];

bool skipPath(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.contains('/l10n/generated/') ||
    path.contains('/.dart_tool/');

bool _isCommentLine(String line) => line.trimLeft().startsWith('//');

/// Directives that must survive trimming regardless of block length.
bool _isPreserved(String line) {
  final t = line.trimLeft();
  return t.startsWith('// ignore') ||
      t.startsWith('//ignore') ||
      t.startsWith('// TODO') ||
      t.startsWith('// FIXME') ||
      t.startsWith('// coverage') ||
      t.startsWith('// dart format');
}

/// Splits on sentence ends only: a period inside `v1.1.0`, `Duration.add` or
/// `e.g.` is not a boundary, so a trim never cuts an identifier in half.
List<String> _splitSentences(String text) {
  final out = <String>[];
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    buffer.write(char);
    if (char != '.' && char != '!' && char != '?') continue;

    final next = i + 1 < text.length ? text[i + 1] : ' ';
    if (next != ' ') continue;

    final after = i + 2 < text.length ? text[i + 2] : 'A';
    final startsNewSentence =
        after == after.toUpperCase() && after != after.toLowerCase();
    final before = i > 0 ? text[i - 1] : ' ';
    final looksLikeAbbreviation =
        (before == '.' || RegExp(r'\d').hasMatch(before)) && char == '.';

    if (startsNewSentence && !looksLikeAbbreviation) {
      out.add(buffer.toString().trim());
      buffer.clear();
      i += 1;
    }
  }

  final rest = buffer.toString().trim();
  if (rest.isNotEmpty) out.add(rest);
  return out.where((s) => s.isNotEmpty).toList();
}

/// Last resort for a single sentence that alone blows the budget: cut on a word
/// boundary and mark it, so the truncation is visible rather than silent.
String _truncateWords(String sentence, int budget) {
  if (sentence.length <= budget) return sentence;
  final kept = <String>[];
  var used = 0;
  for (final word in sentence.split(RegExp(r'\s+'))) {
    if (used + word.length + 1 > budget - 4) break;
    kept.add(word);
    used += word.length + 1;
  }
  if (kept.isEmpty) return '${sentence.substring(0, budget - 4)} ...';
  return '${kept.join(' ')} ...';
}

/// Keeps whole sentences only, rewrapped, so a trim never ends mid-thought.
List<String> _firstSentences(String text, String marker, String indent) {
  final width = 80 - indent.length - marker.length - 1;
  final sentences = _splitSentences(text);

  final chosen = <String>[];
  var lineCount = 0;

  for (final sentence in sentences) {
    final candidate = [...chosen, sentence].join(' ');
    final wrapped = _wrap(candidate, width);
    final overBudget =
        wrapped.length > maxBlockLines || candidate.length > maxBlockChars;
    if (overBudget && chosen.isNotEmpty) break;
    if (overBudget && chosen.isEmpty) {
      return _wrap(
        _truncateWords(sentence, maxBlockChars),
        width,
      ).take(maxBlockLines).map((l) => '$indent$marker $l').toList();
    }
    chosen.add(sentence);
    lineCount = wrapped.length;
  }

  if (chosen.isEmpty) {
    return ['$indent$marker ${_truncateWords(sentences.first, maxBlockChars)}'];
  }
  assert(
    lineCount <= maxBlockLines,
    'The chosen sentences wrapped to $lineCount lines, over $maxBlockLines.',
  );
  return _wrap(
    chosen.join(' '),
    width,
  ).map((l) => '$indent$marker $l').toList();
}

List<String> _wrap(String text, int width) {
  final lines = <String>[];
  final buffer = StringBuffer();
  for (final word in text.split(RegExp(r'\s+'))) {
    if (buffer.isEmpty) {
      buffer.write(word);
    } else if (buffer.length + 1 + word.length <= width) {
      buffer.write(' $word');
    } else {
      lines.add(buffer.toString());
      buffer
        ..clear()
        ..write(word);
    }
  }
  if (buffer.isNotEmpty) lines.add(buffer.toString());
  return lines;
}

class TrimResult {
  TrimResult(this.lines, this.trimmed);
  final List<String> lines;
  final int trimmed;
}

TrimResult trimSource(List<String> lines) {
  final out = <String>[];
  final block = <String>[];
  var trimmed = 0;

  void flush() {
    if (block.isEmpty) return;
    final preserved = block.where(_isPreserved).toList();
    final prose = block.where((l) => !_isPreserved(l)).toList();

    if (prose.isEmpty) {
      out.addAll(block);
      block.clear();
      return;
    }

    final indent = ' ' * (prose.first.length - prose.first.trimLeft().length);
    final marker = prose.first.trimLeft().startsWith('///') ? '///' : '//';
    final text = prose
        .map((l) => l.trimLeft().replaceFirst(RegExp(r'^/+\s?'), ''))
        .join(' ')
        .trim();

    if (prose.length <= maxBlockLines && text.length <= maxBlockChars) {
      out.addAll(block);
      block.clear();
      return;
    }

    final kept = _firstSentences(text, marker, indent);
    final keptChars = kept
        .map((l) => l.trimLeft().replaceFirst(RegExp(r'^/+\s?'), '').length)
        .fold(0, (a, b) => a + b);
    trimmed += text.length - keptChars;
    out
      ..addAll(preserved)
      ..addAll(kept);
    block.clear();
  }

  for (final line in lines) {
    if (_isCommentLine(line)) {
      block.add(line);
    } else {
      flush();
      out.add(line);
    }
  }
  flush();
  return TrimResult(out, trimmed);
}

/// Where the ratchet's baseline lives. `test/style/comment_budget_test.dart`
/// reads the same path.
const baselinePath = 'test/style/comment_budget_baseline.json';

void main(List<String> args) {
  final fix = args.contains('--fix');
  final updateBaseline = args.contains('--update-baseline');
  final only = args.where((a) => !a.startsWith('--')).toList();
  var totalTrimmed = 0;
  final touched = <String, int>{};

  final targets = only.isEmpty
      ? _scanned
            .map(Directory.new)
            .where((d) => d.existsSync())
            .expand((d) => d.listSync(recursive: true))
            .whereType<File>()
      : only.map(File.new).where((f) => f.existsSync());

  for (final entity in targets) {
    if (!entity.path.endsWith('.dart')) continue;
    if (skipPath(entity.path)) continue;

    final result = trimSource(entity.readAsLinesSync());
    if (result.trimmed == 0) continue;

    totalTrimmed += result.trimmed;
    touched[entity.path] = result.trimmed;
    if (fix) {
      entity.writeAsStringSync('${result.lines.join('\n')}\n');
    }
  }

  if (updateBaseline) {
    final sorted = Map.fromEntries(
      touched.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    File(baselinePath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
    stdout.writeln(
      'baseline written: ${sorted.length} files, '
      '$totalTrimmed excess comment characters',
    );
    return;
  }

  final ranked = touched.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in ranked.take(25)) {
    stdout.writeln('  ${entry.value.toString().padLeft(4)}  ${entry.key}');
  }
  stdout.writeln(
    '${fix ? "trimmed" : "would trim"} $totalTrimmed comment characters '
    'across ${touched.length} files '
    '(max $maxBlockLines lines / $maxBlockChars chars per block)',
  );
  if (!fix && totalTrimmed > 0) exitCode = 1;
}
