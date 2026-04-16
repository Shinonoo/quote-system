// excel_export_web.dart
// Used on Web: triggers a browser file download.

import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadExcelOnWeb(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Stub so the file compiles on all platforms via conditional import.
Future<dynamic> getMobileFile(Uint8List bytes, String filename) async =>
    throw UnsupportedError('getMobileFile not available on web');