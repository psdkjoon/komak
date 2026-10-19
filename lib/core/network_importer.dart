import 'package:komak/core/deck_importer.dart';
import 'package:komak/core/http_fetcher.dart';
import 'package:komak/core/import_result.dart';
import 'package:komak/core/text_decoder.dart';

class NetworkImportException implements Exception {
  NetworkImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkImporter {
  NetworkImporter({DeckImporter? importer})
      : _importer = importer ?? DeckImporter();

  final DeckImporter _importer;
  static const int _maxBytes = 5 * 1024 * 1024;

  Future<ImportResult> importFromUrl(
    String url, {
    String encoding = TextDecoder.auto,
  }) async {
    Uri uri;
    try {
      uri = Uri.parse(url.trim());
    } catch (_) {
      throw NetworkImportException('That does not look like a valid URL.');
    }

    if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw NetworkImportException('Only http and https links are supported.');
    }

    late HttpResult response;
    try {
      response = await HttpFetcher.get(uri, maxBytes: _maxBytes);
    } on HttpTooLarge {
      throw NetworkImportException(
        'That file is larger than the 5 MB import limit.',
      );
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

    if (response.bytes.length > _maxBytes) {
      throw NetworkImportException(
        'That file is larger than the 5 MB import limit.',
      );
    }

    final String body =
        TextDecoder.decode(response.bytes, encoding: encoding);
    final ImportFormat format = _resolveFormat(
      contentType: response.contentType,
      url: uri,
      body: body,
    );

    try {
      return _importer.parse(body, format);
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
