import 'dart:convert';
import 'dart:io';

/// Checks every translation in lib/l10n against the English template, so a
/// contributor who only edits an ARB file gets a clear failure instead of a
/// broken build: missing keys, unknown keys, and placeholder mismatches.
///
/// Run with `dart run tool/verify_translations.dart`. Exits non-zero on error.
Future<void> main() async {
  const dirPath = 'lib/l10n';
  const templateName = 'app_en.arb';

  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    stderr.writeln('missing $dirPath');
    exit(1);
  }

  final template = _load('$dirPath/$templateName');
  final templateKeys = _messageKeys(template);
  final problems = <String>[];

  if (!templateKeys.contains('languageName')) {
    problems.add('$templateName: missing the "languageName" key');
  }

  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .where((f) => !f.path.endsWith(templateName))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final arb = _load(file.path);
    final keys = _messageKeys(arb);

    for (final key in templateKeys.difference(keys)) {
      problems.add('$name: missing key "$key"');
    }
    for (final key in keys.difference(templateKeys)) {
      problems.add('$name: unknown key "$key" (not in $templateName)');
    }
    for (final key in templateKeys.intersection(keys)) {
      final expected = _placeholders(template[key] as String);
      final actual = _placeholders(arb[key] as String);
      for (final missing in expected.difference(actual)) {
        problems.add('$name: "$key" is missing the {$missing} placeholder');
      }
      for (final extra in actual.difference(expected)) {
        problems.add('$name: "$key" has an unexpected {$extra} placeholder');
      }
    }
  }

  final languages = [
    templateName,
    ...files.map((f) => f.uri.pathSegments.last),
  ];
  stdout.writeln(
    'Checked ${languages.length} languages: ${languages.join(', ')}',
  );

  if (problems.isEmpty) {
    stdout.writeln('${templateKeys.length} keys, all translations consistent.');
    return;
  }
  stderr.writeln('\nFound ${problems.length} problem(s):');
  for (final problem in problems) {
    stderr.writeln('  $problem');
  }
  stderr.writeln(
    '\nEvery language file must carry exactly the same keys as $templateName, '
    'with the same {placeholders} inside each message.',
  );
  exit(1);
}

Map<String, dynamic> _load(String path) {
  final text = File(path).readAsStringSync();
  return jsonDecode(text) as Map<String, dynamic>;
}

/// The translatable keys: ARB metadata ("@key", "@@locale") is not a message.
Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// The placeholder names a message uses, so a translation cannot silently drop
/// or invent one. Matches {name} and {name, plural, so the first word of an ICU
/// branch such as =1{expires in 1 day} is not read as a placeholder.
Set<String> _placeholders(String message) => RegExp(r'\{(\w+)\s*[,}]')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .where((name) => !_icuKeywords.contains(name))
    .toSet();

const _icuKeywords = {
  'plural',
  'select',
  'other',
  'zero',
  'one',
  'two',
  'few',
  'many',
};
