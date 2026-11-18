import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `ExcludeSemantics` drops the `InkWell`'s tap from the tree, so the
/// `Semantics` button above it must carry the action itself.
List<String> buttonsWithoutAction(String source, String path) {
  final offenders = <String>[];
  final opener = RegExp(r'(?<![A-Za-z])Semantics\(');
  for (final match in opener.allMatches(source)) {
    final args = _argumentsBeforeChild(source, match.end);
    if (args == null) continue;
    final named = _topLevel(args);
    if (named['button'] != 'true') continue;
    final child = source.substring(match.end + args.length).trimLeft();
    if (!child.startsWith('child: ExcludeSemantics(')) continue;
    final excludeArgs = child.substring(0, child.length.clamp(0, 80));
    if (excludeArgs.contains('excluding: false')) continue;
    if (named.containsKey('onTap') || named.containsKey('onLongPress')) {
      continue;
    }
    final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
    offenders.add('$path:$line');
  }
  return offenders;
}

Map<String, String> _topLevel(String args) {
  final named = <String, String>{};
  var depth = 0;
  var start = 0;
  void take(int end) {
    final part = args.substring(start, end).trim();
    final colon = part.indexOf(':');
    if (colon > 0) {
      named[part.substring(0, colon).trim()] = part.substring(colon + 1).trim();
    }
  }

  for (var i = 0; i < args.length; i++) {
    final c = args[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ',' && depth == 0) {
      take(i);
      start = i + 1;
    }
  }
  take(args.length);
  return named;
}

String? _argumentsBeforeChild(String source, int start) {
  var depth = 0;
  for (var i = start; i < source.length; i++) {
    final c = source[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return null;
      depth--;
    }
    if (depth == 0 && source.startsWith('child:', i)) {
      return source.substring(start, i);
    }
  }
  return null;
}

void main() {
  test('every Semantics button over ExcludeSemantics has a tap action', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          ...buttonsWithoutAction(file.readAsStringSync(), file.path),
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'A screen reader finds these buttons but cannot press them.',
    );
  });

  group('the scan itself', () {
    test('flags a button whose tap was excluded', () {
      const source = '''
Semantics(
  button: true,
  label: label,
  child: ExcludeSemantics(child: InkWell(onTap: onTap, child: x)),
)''';
      expect(buttonsWithoutAction(source, 'x.dart'), ['x.dart:1']);
    });

    test('passes one that carries onTap or onLongPress', () {
      for (final action in ['onTap: onTap', 'onLongPress: hold']) {
        final source =
            'Semantics(button: true, $action, '
            'child: ExcludeSemantics(child: x))';
        expect(buttonsWithoutAction(source, 'x.dart'), isEmpty);
      }
    });

    test('passes when the child keeps its own semantics', () {
      const source =
          'Semantics(button: true, '
          'child: ExcludeSemantics(excluding: false, child: x))';
      expect(buttonsWithoutAction(source, 'x.dart'), isEmpty);
    });

    test('ignores onTap nested inside an argument, not on the node', () {
      const source =
          'Semantics(button: true, label: f(onTap: g), '
          'child: ExcludeSemantics(child: x))';
      expect(buttonsWithoutAction(source, 'x.dart'), ['x.dart:1']);
    });
  });
}
