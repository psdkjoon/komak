import 'dart:async';
import 'dart:io';

class HttpResult {
  const HttpResult(this.statusCode, this.bytes, this.contentType);

  final int statusCode;
  final List<int> bytes;
  final String? contentType;
}

class HttpTooLarge implements Exception {
  const HttpTooLarge();
}

abstract class HttpFetcher {
  static Future<HttpResult> get(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
    int? maxBytes,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (maxBytes != null && bytes.length > maxBytes) {
          throw const HttpTooLarge();
        }
      }
      return HttpResult(
        response.statusCode,
        bytes,
        response.headers.contentType?.mimeType,
      );
    } finally {
      client.close(force: true);
    }
  }
}
