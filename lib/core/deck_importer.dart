import 'dart:convert';

import 'package:komak/core/csv_parser.dart';
import 'package:komak/core/import_result.dart';
import 'package:komak/decks/flashcard.dart';

enum ImportFormat { json, csv, delimitedText }

class DeckImporter {
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
      final String? front = _text(entry['front']) ??
          _text(entry['question']) ??
          _text(entry['term']);
      final String? back = _text(entry['back']) ??
          _text(entry['answer']) ??
          _text(entry['meaning']);
      if (front == null || back == null) {
        warnings.add('Skipped a card missing a front or back value.');
        continue;
      }
      cards.add(
        Flashcard(
          front: front,
          back: back,
          reading: _text(entry['reading']),
          example: _text(entry['example']),
          note: _text(entry['note']),
          orderIndex: entry['orderIndex'] as int?,
          groupId: _text(entry['groupId']) ?? _text(entry['group']),
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

  static const List<String> _frontWords = <String>[
    'front',
    'question',
    'term',
    'word',
    'name',
  ];
  static const List<String> _backWords = <String>[
    'back',
    'answer',
    'meaning',
    'definition',
  ];
  static const List<String> _readingWords = <String>[
    'reading',
    'pronunciation',
    'phonetic',
    'romaji',
    'pinyin',
  ];
  static const List<String> _exampleWords = <String>['example', 'sentence'];
  static const List<String> _noteWords = <String>[
    'note',
    'mnemonic',
    'hint',
    'extra',
  ];
  static const List<String> _orderWords = <String>['order', 'position'];
  static const List<String> _groupWords = <String>[
    'group',
    'category',
    'tag',
    'chapter',
  ];

  static String? _text(Object? value) {
    if (value == null) return null;
    final String clean = '$value'.trim();
    return clean.isEmpty ? null : clean;
  }

  static int _find(List<String> header, List<String> words) {
    for (int i = 0; i < header.length; i++) {
      final String name = header[i].trim().toLowerCase();
      if (words.any(name.contains)) return i;
    }
    return -1;
  }

  static String? _cell(List<String> row, int column) {
    if (column < 0 || column >= row.length) return null;
    return _text(row[column]);
  }

  ImportResult parseCsv(String content) {
    final List<List<String>> rows =
        CsvParser.parse(content.replaceFirst('\uFEFF', '').trim());
    final List<String> warnings = <String>[];
    if (rows.isEmpty) {
      return ImportResult(
        cards: const <Flashcard>[],
        warnings: <String>['The CSV file had no rows.'],
      );
    }

    final List<String> firstRow = rows.first;
    int frontColumn = _find(firstRow, _frontWords);
    int backColumn = _find(firstRow, _backWords);
    final bool looksLikeHeader = (frontColumn >= 0 && backColumn >= 0) ||
        (firstRow.isNotEmpty &&
            firstRow[0].trim().toLowerCase().contains('front'));

    int startIndex = 0;
    int readingColumn = -1;
    int exampleColumn = -1;
    int noteColumn = -1;
    int orderColumn = -1;
    int groupColumn = -1;

    if (looksLikeHeader) {
      startIndex = 1;
      if (frontColumn < 0) frontColumn = 0;
      if (backColumn < 0) backColumn = 1;
      readingColumn = _find(firstRow, _readingWords);
      exampleColumn = _find(firstRow, _exampleWords);
      noteColumn = _find(firstRow, _noteWords);
      orderColumn = _find(firstRow, _orderWords);
      groupColumn = _find(firstRow, _groupWords);
    } else {
      frontColumn = 0;
      backColumn = 1;
      if (firstRow.length >= 4) {
        orderColumn = 2;
        groupColumn = 3;
      }
    }

    final List<Flashcard> cards = <Flashcard>[];
    for (int i = startIndex; i < rows.length; i++) {
      final List<String> row = rows[i];
      if (row.length <= backColumn || row.length <= frontColumn) {
        warnings.add('Skipped row ${i + 1}: not enough columns.');
        continue;
      }
      final String front = row[frontColumn].trim();
      final String back = row[backColumn].trim();
      if (front.isEmpty || back.isEmpty) {
        warnings.add('Skipped row ${i + 1}: empty front or back.');
        continue;
      }
      cards.add(
        Flashcard(
          front: front,
          back: back,
          reading: _cell(row, readingColumn),
          example: _cell(row, exampleColumn),
          note: _cell(row, noteColumn),
          orderIndex: int.tryParse(_cell(row, orderColumn) ?? ''),
          groupId: _cell(row, groupColumn),
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
