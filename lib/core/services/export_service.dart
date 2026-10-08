import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:komak/core/models/deck.dart';

enum ExportFormat { json, csv, delimitedText }

class ExportService {
  String buildJson(Deck deck) {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': deck.title,
      'description': deck.description,
      'cards': deck.cards
          .map(
            (card) => <String, dynamic>{
              'front': card.front,
              'back': card.back,
              if (card.orderIndex != null) 'orderIndex': card.orderIndex,
              if (card.groupId != null) 'groupId': card.groupId,
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String buildCsv(Deck deck) {
    final StringBuffer buffer = StringBuffer('front,back,orderIndex,groupId\n');
    for (final card in deck.cards) {
      buffer.writeln(
        <String>[
          _escapeCsv(card.front),
          _escapeCsv(card.back),
          card.orderIndex?.toString() ?? '',
          card.groupId ?? '',
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String buildDelimitedText(Deck deck) {
    final StringBuffer buffer = StringBuffer();
    for (final card in deck.cards) {
      final String front = card.front.replaceAll('\n', r'\n');
      final String back = card.back.replaceAll('\n', r'\n');
      buffer.writeln('$front=:=$back');
    }
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll("\"", "\"\"")}"';
    }
    return value;
  }

  Future<File> saveToDisk(Deck deck, ExportFormat format) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory exportsDirectory =
        Directory('${directory.path}/psdk_komak_exports');
    if (!await exportsDirectory.exists()) {
      await exportsDirectory.create(recursive: true);
    }

    final String slug =
        deck.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final String extension = switch (format) {
      ExportFormat.json => 'json',
      ExportFormat.csv => 'csv',
      ExportFormat.delimitedText => 'txt',
    };
    final String content = switch (format) {
      ExportFormat.json => buildJson(deck),
      ExportFormat.csv => buildCsv(deck),
      ExportFormat.delimitedText => buildDelimitedText(deck),
    };

    final File file = File('${exportsDirectory.path}/$slug.$extension');
    await file.writeAsString(content);
    return file;
  }
}
