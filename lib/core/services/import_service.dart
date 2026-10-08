import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/services/import_result.dart';

enum ImportFormat { json, csv, delimitedText }

class ImportService {
  ImportResult parse(String content, ImportFormat format) {
    switch (format) {
      case ImportFormat.json:
        return parseJson(content);
      case ImportFormat.csv:
        return parseCsv(content);
      case ImportFormat.delimitedText:
        return parseDelimitedText(content);
    }
  }

  ImportResult parseJson(String content) {
    final dynamic decoded = jsonDecode(content);
    final List<String> warnings = <String>[];

    List<dynamic> rawCards;
    String? title;
    String? description;

    if (decoded is Map<String, dynamic>) {
      title = decoded['title'] as String?;
      description = decoded['description'] as String?;
      rawCards = (decoded['cards'] as List<dynamic>?) ?? <dynamic>[];
    } else if (decoded is List<dynamic>) {
      rawCards = decoded;
    } else {
      throw const FormatException(
        'Unrecognised JSON shape for an import file.',
      );
    }

    final List<Flashcard> cards = <Flashcard>[];
    for (final dynamic entry in rawCards) {
      if (entry is! Map<String, dynamic>) {
        warnings.add('Skipped a card entry that was not an object.');
        continue;
      }
      final String? front =
          entry['front'] as String? ?? entry['question'] as String?;
      final String? back =
          entry['back'] as String? ?? entry['answer'] as String?;
      if (front == null ||
          back == null ||
          front.trim().isEmpty ||
          back.trim().isEmpty) {
        warnings.add('Skipped a card missing a front or back value.');
        continue;
      }
      cards.add(
        Flashcard(
          front: front,
          back: back,
          orderIndex: entry['orderIndex'] as int?,
          groupId: entry['groupId'] as String?,
        ),
      );
    }

    return ImportResult(
      cards: cards,
      deckTitle: title,
      deckDescription: description,
      warnings: warnings,
    );
  }

  ImportResult parseCsv(String content) {
    final List<List<dynamic>> rows =
        const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
            .convert(content.trim());
    final List<String> warnings = <String>[];
    if (rows.isEmpty) {
      return ImportResult(
        cards: const <Flashcard>[],
        warnings: <String>['The CSV file had no rows.'],
      );
    }

    int startIndex = 0;
    final List<dynamic> firstRow = rows.first;
    final bool looksLikeHeader = firstRow.isNotEmpty &&
        firstRow[0].toString().trim().toLowerCase().contains('front') == true;
    int frontColumn = 0;
    int backColumn = 1;
    int orderColumn = -1;
    int groupColumn = -1;

    if (looksLikeHeader) {
      startIndex = 1;
      for (int i = 0; i < firstRow.length; i++) {
        final String columnName = firstRow[i].toString().trim().toLowerCase();
        if (columnName.contains('front') || columnName.contains('question')) {
          frontColumn = i;
        }
        if (columnName.contains('back') || columnName.contains('answer')) {
          backColumn = i;
        }
        if (columnName.contains('order')) orderColumn = i;
        if (columnName.contains('group')) groupColumn = i;
      }
    }

    final List<Flashcard> cards = <Flashcard>[];
    for (int i = startIndex; i < rows.length; i++) {
      final List<dynamic> row = rows[i];
      if (row.length <= backColumn || row.length <= frontColumn) {
        warnings.add('Skipped row ${i + 1}: not enough columns.');
        continue;
      }
      final String front = row[frontColumn].toString().trim();
      final String back = row[backColumn].toString().trim();
      if (front.isEmpty || back.isEmpty) {
        warnings.add('Skipped row ${i + 1}: empty front or back.');
        continue;
      }
      final int? orderIndex = orderColumn >= 0 && row.length > orderColumn
          ? int.tryParse(row[orderColumn].toString().trim())
          : null;
      final String? groupId = groupColumn >= 0 && row.length > groupColumn
          ? row[groupColumn].toString().trim()
          : null;

      cards.add(
        Flashcard(
          front: front,
          back: back,
          orderIndex: orderIndex,
          groupId: groupId?.isEmpty ?? true ? null : groupId,
        ),
      );
    }

    return ImportResult(cards: cards, warnings: warnings);
  }

  ImportResult parseDelimitedText(String content) {
    const String separator = '=:=';
    final List<String> lines = content.split('\n');
    final List<Flashcard> cards = <Flashcard>[];
    final List<String> warnings = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final String rawLine = lines[i].trim();
      if (rawLine.isEmpty) continue;
      final int separatorIndex = rawLine.indexOf(separator);
      if (separatorIndex == -1) {
        warnings
            .add('Skipped line ${i + 1}: missing the $separator separator.');
        continue;
      }
      final String front =
          rawLine.substring(0, separatorIndex).trim().replaceAll(r'\n', '\n');
      final String back = rawLine
          .substring(separatorIndex + separator.length)
          .trim()
          .replaceAll(r'\n', '\n');
      if (front.isEmpty || back.isEmpty) {
        warnings.add('Skipped line ${i + 1}: empty front or back.');
        continue;
      }
      cards.add(Flashcard(front: front, back: back));
    }

    return ImportResult(cards: cards, warnings: warnings);
  }
}
