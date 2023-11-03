// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Generates and updates HTML entities.
void main() {
  // Original file: https://html.spec.whatwg.org/entities.json
  final file = File('${p.current}/tool/entities.json');
  final json = file.readAsStringSync();
  final map = Map<String, Map<String, dynamic>>.from(jsonDecode(json) as Map);

  final result = <String, String>{};
  for (final name in map.keys) {
    if (name.endsWith(';')) {
      final value = map[name]!['characters'] as String;
      result[name] = value;
    }
  }

  final outputPath = '${p.current}/lib/src/assets/html_entities.dart';
  var stringMap = const JsonEncoder.withIndent('  ')
      .convert(result)
      .replaceAll(r'"$"', r'r"$"')
      .replaceAll(r'"\\"', r'r"\"');

  final reg = RegExp('"(.*?)"(:)');
  stringMap = stringMap.replaceAllMapped(reg, (match) {
    // String originStr = match.group(0)!;
    final replaceStr = match.group(1)!;
    final endStr = match.group(2)!;

    var newStr = replaceEncryStringByList(replaceStr);
    newStr += endStr;

    print('$replaceStr,$newStr');

    return newStr;
  });

  final output = '''
// Generated file. do not edit.
//
// Source: tool/entities.json
// Script: tool/update_entities.dart
// ignore_for_file: prefer_single_quotes

final htmlEntitiesMap = $stringMap;
''';
  File(outputPath).writeAsStringSync(output);
}

String replaceEncryStringByList(String replaceStr) {
  replaceStr = replaceStr.replaceAll(r'\n', '\n');

  var newStr = '[';

  final codePoints = replaceStr.runes;
  final list = <String>[];
  for (final element in codePoints) {
    list.add(String.fromCharCode(element));
  }

  for (var codeUnit in list) {
    if (codeUnit == '"') {
      codeUnit = r'\"';
    }
    if (codeUnit == '\n') {
      codeUnit = r'\n';
    }

    // ignore: use_string_buffers
    newStr += '"$codeUnit",';
  }
  newStr += '].join()';
  // print(newStr);

  return newStr;
}
