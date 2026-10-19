import 'dart:convert';
import 'dart:io';

import 'package:komak/core/app_dirs.dart';
import 'package:komak/decks/deck.dart';

enum ExportFormat { json, csv, delimitedText }

class DeckExporter {
  String buildJson(Deck deck) {
    final payload = <String, dynamic>{
      'title': deck.title,
      'description': deck.description,
      'cards': deck.cards
          .map(
            (card) => <String, dynamic>{
              'front': card.front,
              'back': card.back,
              if (card.reading != null) 'reading': card.reading,
              if (card.example != null) 'example': card.example,
              if (card.note != null) 'note': card.note,
              if (card.orderIndex != null) 'orderIndex': card.orderIndex,
              if (card.groupId != null) 'groupId': card.groupId,
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String buildCsv(Deck deck) {
    final buffer = StringBuffer('front,back,reading,example,note,orderIndex,groupId\n');
    for (final card in deck.cards) {
      buffer.writeln(
        [
          _escapeCsv(card.front),
          _escapeCsv(card.back),
          _escapeCsv(card.reading ?? ''),
          _escapeCsv(card.example ?? ''),
          _escapeCsv(card.note ?? ''),
          card.orderIndex?.toString() ?? '',
          _escapeCsv(card.groupId ?? ''),
        ].join(','),
      );
    }
    return '\uFEFF${buffer.toString()}';
  }

  String buildDelimitedText(Deck deck) {
    final buffer = StringBuffer();
    for (final card in deck.cards) {
      final front = card.front.replaceAll('\n', r'\n');
      final back = card.back.replaceAll('\n', r'\n');
      buffer.writeln('$front=:=$back');
    }
    return buffer.toString();
  }

  String _slugFor(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'deck' : slug;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll("\"", "\"\"")}"';
    }
    return value;
  }

  Future<File> saveToDisk(Deck deck, ExportFormat format) async {
    final exportsDirectory =
        Directory('${await AppDirs.data()}/exports');
    if (!await exportsDirectory.exists()) {
      await exportsDirectory.create(recursive: true);
    }

    final slug = _slugFor(deck.title);
    final extension = switch (format) {
      ExportFormat.json => 'json',
      ExportFormat.csv => 'csv',
      ExportFormat.delimitedText => 'txt',
    };
    final content = switch (format) {
      ExportFormat.json => buildJson(deck),
      ExportFormat.csv => buildCsv(deck),
      ExportFormat.delimitedText => buildDelimitedText(deck),
    };

    final file = File('${exportsDirectory.path}/$slug.$extension');
    await file.writeAsString(content);
    return file;
  }
}
