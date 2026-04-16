// excel_export_stub.dart
// Used on Mobile / Desktop: saves the file to the temp directory and returns a File.

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<File> getMobileFile(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

// Stub so the file compiles on all platforms via conditional import.
void downloadExcelOnWeb(Uint8List bytes, String filename) =>
    throw UnsupportedError('downloadExcelOnWeb not available on mobile/desktop');