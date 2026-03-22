import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

/// On native/desktop/mobile, appends a timestamped, pretty-printed snapshot to
/// `{applicationSupportDirectory}/rich_text_document_json.log`.
///
/// On web, prints the same payload with [debugPrint] (no filesystem).
Future<void> appendRichTextDocumentJsonLog(
  Map<String, Object> documentJson,
) async {
  final payload = const JsonEncoder.withIndent('  ').convert(documentJson);
  final header = '--- ${DateTime.now().toUtc().toIso8601String()} ---\n';
  final body = '$header$payload';

  if (kIsWeb) {
    debugPrint('[rich_text_document_json.log]\n$body');
    return;
  }

  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/rich_text_document_json.log');
    await file.writeAsString(
      '$body\n\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (e, st) {
    debugPrint('appendRichTextDocumentJsonLog failed: $e\n$st');
  }
}
