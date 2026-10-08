import 'package:http/http.dart' as http;
import 'package:komak/core/services/import_result.dart';
import 'package:komak/core/services/import_service.dart';

class NetworkImportException implements Exception {
  NetworkImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkImportService {
  NetworkImportService({ImportService? importService})
      : _importService = importService ?? ImportService();

  final ImportService _importService;
  static const int _maxBytes = 5 * 1024 * 1024;

  Future<ImportResult> importFromUrl(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url.trim());
    } catch (_) {
      throw NetworkImportException('That does not look like a valid URL.');
    }

    if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw NetworkImportException('Only http and https links are supported.');
    }

    late http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw NetworkImportException(
        'Could not reach that link. Check your connection and the URL.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NetworkImportException(
        'The link responded with status code ${response.statusCode}.',
      );
    }

    if (response.bodyBytes.length > _maxBytes) {
      throw NetworkImportException(
        'That file is larger than the 5 MB import limit.',
      );
    }

    final ImportFormat format = _resolveFormat(
      contentType: response.headers['content-type'],
      url: uri,
      body: response.body,
    );

    try {
      return _importService.parse(response.body, format);
    } on FormatException catch (error) {
      throw NetworkImportException(
        'Could not parse the response: ${error.message}',
      );
    }
  }

  ImportFormat _resolveFormat({
    required String? contentType,
    required Uri url,
    required String body,
  }) {
    final String normalizedType = (contentType ?? '').toLowerCase();
    if (normalizedType.contains('json')) return ImportFormat.json;
    if (normalizedType.contains('csv')) return ImportFormat.csv;

    final String path = url.path.toLowerCase();
    if (path.endsWith('.json')) return ImportFormat.json;
    if (path.endsWith('.csv')) return ImportFormat.csv;
    if (path.endsWith('.txt')) return ImportFormat.delimitedText;

    final String trimmedBody = body.trim();
    if (trimmedBody.startsWith('{') || trimmedBody.startsWith('[')) {
      return ImportFormat.json;
    }
    if (body.contains('=:=')) return ImportFormat.delimitedText;
    return ImportFormat.csv;
  }
}
