import 'package:komak/core/http_fetcher.dart';
import 'package:komak/core/store_config.dart';
import 'package:komak/core/store_entry.dart';
import 'package:komak/core/text_decoder.dart';

class StoreException implements Exception {
  StoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StoreClient {
  Future<List<StoreEntry>> fetchIndex() async {
    StoreException? failure;
    for (final String url in storeIndexUrls) {
      try {
        return await _fetchFrom(Uri.parse(url));
      } on StoreException catch (error) {
        failure ??= error;
      }
    }
    throw failure ?? StoreException('Could not reach the store. Check your connection.');
  }

  Future<List<StoreEntry>> _fetchFrom(Uri base) async {
    late HttpResult response;
    try {
      response = await HttpFetcher.get(base);
    } catch (_) {
      throw StoreException('Could not reach the store. Check your connection.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StoreException(
        'The store responded with status code ${response.statusCode}.',
      );
    }
    final List<StoreEntry> entries =
        parseIndex(TextDecoder.decode(response.bytes), base);
    if (entries.isEmpty) throw StoreException('The store is empty right now.');
    return entries;
  }

  static List<StoreEntry> parseIndex(String body, Uri base) {
    final List<StoreEntry> entries = <StoreEntry>[];
    for (final String rawLine in body.split('\n')) {
      final String line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final List<String> parts =
          line.split('|').map((String p) => p.trim()).toList();
      final String location = parts.last;
      if (location.isEmpty) continue;
      final Uri resolved = base.resolve(location);
      final String title = parts.length >= 2 && parts.first.isNotEmpty
          ? parts.first
          : _titleFromUri(resolved);
      final String description = parts.length >= 3 ? parts[1] : '';
      entries.add(
        StoreEntry(
          title: title,
          description: description,
          url: resolved.toString(),
        ),
      );
    }
    return entries;
  }

  static String _titleFromUri(Uri uri) {
    final String last = uri.pathSegments.isEmpty
        ? 'Deck'
        : Uri.decodeComponent(uri.pathSegments.last);
    final String name =
        last.contains('.') ? last.substring(0, last.lastIndexOf('.')) : last;
    final String spaced = name.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return 'Deck';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
