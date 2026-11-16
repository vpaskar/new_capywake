// ARB completeness gate. Ensures every non-template ARB has exactly the same
// message keys as the English template (no missing keys, no stray keys). With
// 10 shipped locales a single missing key is an easy regression; this catches
// it in validation:
//
//   dart run tool/check_arb.dart
//
// Flags:
//   --dir <path>        ARB directory (default lib/l10n).
//   --template <file>   Template ARB filename (default app_en.arb).
//   --allow-extra       Don't fail on keys present in a locale but not the
//                       template (default: extras are an error).
//
// Metadata keys (@-prefixed) and @@locale are ignored — only message keys
// count.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  var dir = 'lib/l10n';
  var templateName = 'app_en.arb';
  var allowExtra = false;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--dir':
        dir = args[++i];
      case '--template':
        templateName = args[++i];
      case '--allow-extra':
        allowExtra = true;
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        exit(2);
    }
  }

  Set<String> messageKeys(File f) {
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return json.keys.where((k) => !k.startsWith('@')).toSet();
  }

  final templateFile = File('$dir/$templateName');
  if (!templateFile.existsSync()) {
    stderr.writeln('Template not found: ${templateFile.path}');
    exit(2);
  }
  final templateKeys = messageKeys(templateFile);

  final arbs =
      Directory(dir)
          .listSync()
          .whereType<File>()
          .where(
            (f) => f.path.endsWith('.arb') && !f.path.endsWith(templateName),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var failed = false;
  for (final arb in arbs) {
    final keys = messageKeys(arb);
    final missing = templateKeys.difference(keys);
    final extra = keys.difference(templateKeys);
    final name = arb.uri.pathSegments.last;

    if (missing.isEmpty && (extra.isEmpty || allowExtra)) {
      stdout.writeln('OK   $name (${keys.length} keys)');
      continue;
    }
    failed = true;
    stdout.writeln('FAIL $name');
    if (missing.isNotEmpty) {
      stderr.writeln(
        '  missing ${missing.length}: ${(missing.toList()..sort()).join(", ")}',
      );
    }
    if (extra.isNotEmpty && !allowExtra) {
      stderr.writeln(
        '  extra ${extra.length}: ${(extra.toList()..sort()).join(", ")}',
      );
    }
  }

  if (failed) {
    stderr.writeln(
      '\nARB check failed. Every locale must match $templateName.',
    );
    exit(1);
  }
  stdout.writeln(
    '\nAll ${arbs.length} locales complete against $templateName.',
  );
}
