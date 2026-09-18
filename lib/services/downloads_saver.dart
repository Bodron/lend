import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DownloadsSaver {
  DownloadsSaver._();

  static const _channel = MethodChannel('lend/downloads');

  static Future<String> savePdf({
    required String name,
    required Uint8List bytes,
  }) async {
    final fileName = name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final uri = await _channel.invokeMethod<String>('savePdfToDownloads', {
        'name': fileName,
        'bytes': bytes,
      });

      if (uri == null || uri.isEmpty) {
        throw Exception('Nu am putut salva contractul in Downloads.');
      }

      return uri;
    }

    return FileSaver.instance.saveFile(
      name: fileName.replaceFirst(RegExp(r'\.pdf$'), ''),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<String> downloadPdfFromUrl({
    required String name,
    required Uri url,
  }) async {
    final fileName = name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final result = await FileSaver.instance.downloadLink(
        link: LinkDetails(link: url.toString()),
        name: fileName,
      );

      if (result == null || result.isEmpty) {
        throw Exception('Nu am putut porni descarcarea contractului.');
      }

      return result;
    }

    return FileSaver.instance.saveFile(
      name: fileName.replaceFirst(RegExp(r'\.pdf$'), ''),
      link: LinkDetails(link: url.toString()),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
