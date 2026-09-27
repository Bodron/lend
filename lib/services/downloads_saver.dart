import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DownloadsSaver {
  DownloadsSaver._();

  static const _channel = MethodChannel('lend/downloads');

  static Future<String?> savePdf({
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

    final nameWithoutExtension = fileName.replaceFirst(RegExp(r'\.pdf$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return _channel.invokeMethod<String>('savePdfWithPicker', {
        'name': fileName,
        'bytes': bytes,
      });
    }

    return FileSaver.instance.saveFile(
      name: nameWithoutExtension,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<String?> downloadPdfFromUrl({
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

    final nameWithoutExtension = fileName.replaceFirst(RegExp(r'\.pdf$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final response = await http.get(url);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Nu am putut descărca acest contract.');
      }
      final bytes = response.bodyBytes;
      if (bytes.length < 5 ||
          bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46 ||
          bytes[4] != 0x2D) {
        throw Exception('Contractul descărcat nu este un PDF valid.');
      }
      return savePdf(name: fileName, bytes: bytes);
    }

    return FileSaver.instance.saveFile(
      name: nameWithoutExtension,
      link: LinkDetails(link: url.toString()),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
