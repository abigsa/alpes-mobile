import 'dart:typed_data';

Future<void> downloadReportFile(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  throw UnsupportedError(
    'La descarga directa de reportes está configurada para Flutter Web.',
  );
}
