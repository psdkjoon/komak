import 'dart:convert';

import 'package:komak/core/legacy_codepages.dart';
import 'package:komak/localization/localization.dart' show L10n;

class TextEncodingOption {
  const TextEncodingOption(this.id, this.label);

  final String id;
  final String label;
}

abstract class TextDecoder {
  static const String auto = 'auto';

  static const List<TextEncodingOption> options = <TextEncodingOption>[
    TextEncodingOption(auto, 'Auto-detect'),
    TextEncodingOption('utf-8', 'UTF-8'),
    TextEncodingOption('utf-16', 'UTF-16'),
    TextEncodingOption('windows-1256', 'Arabic / Persian (Windows-1256)'),
    TextEncodingOption('windows-1251', 'Cyrillic (Windows-1251)'),
    TextEncodingOption('windows-1252', 'Western (Windows-1252)'),
    TextEncodingOption('windows-1250', 'Central European (Windows-1250)'),
    TextEncodingOption('windows-1253', 'Greek (Windows-1253)'),
    TextEncodingOption('windows-1254', 'Turkish (Windows-1254)'),
    TextEncodingOption('windows-1255', 'Hebrew (Windows-1255)'),
    TextEncodingOption('windows-1257', 'Baltic (Windows-1257)'),
    TextEncodingOption('windows-1258', 'Vietnamese (Windows-1258)'),
    TextEncodingOption('windows-874', 'Thai (Windows-874)'),
    TextEncodingOption('koi8-r', 'Russian (KOI8-R)'),
    TextEncodingOption('shift_jis', 'Japanese (Shift-JIS)'),
    TextEncodingOption('gbk', 'Chinese Simplified (GBK)'),
    TextEncodingOption('big5', 'Chinese Traditional (Big5)'),
    TextEncodingOption('euc-kr', 'Korean (EUC-KR)'),
  ];

  static String decode(List<int> bytes, {String encoding = auto}) {
    if (bytes.isEmpty) return '';
    final String? bom = _bomEncoding(bytes);
    if (encoding == auto) {
      if (bom == 'utf-8') return _utf8(bytes, skip: 3, allowMalformed: true);
      if (bom == 'utf-16le' || bom == 'utf-16be') {
        return _utf16(bytes, bigEndian: bom == 'utf-16be', skip: 2);
      }
      final String? strict = _tryUtf8(bytes);
      if (strict != null) return strict;
      final bool? wideBigEndian = _guessUtf16WithoutBom(bytes);
      if (wideBigEndian != null) {
        return _utf16(bytes, bigEndian: wideBigEndian, skip: 0);
      }
      return _detectLegacy(bytes);
    }
    switch (encoding) {
      case 'utf-8':
        return _utf8(
          bytes,
          skip: bom == 'utf-8' ? 3 : 0,
          allowMalformed: true,
        );
      case 'utf-16':
        return _utf16(
          bytes,
          bigEndian: bom == 'utf-16be' ||
              (bom == null && (_guessUtf16WithoutBom(bytes) ?? false)),
          skip: bom == 'utf-16le' || bom == 'utf-16be' ? 2 : 0,
        );
      default:
        return _legacy(bytes, encoding);
    }
  }

  static String? _bomEncoding(List<int> b) {
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      return 'utf-8';
    }
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) return 'utf-16le';
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) return 'utf-16be';
    return null;
  }

  static String _utf8(
    List<int> bytes, {
    required int skip,
    required bool allowMalformed,
  }) {
    return utf8.decode(
      skip == 0 ? bytes : bytes.sublist(skip),
      allowMalformed: allowMalformed,
    );
  }

  static String? _tryUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  static String _utf16(
    List<int> bytes, {
    required bool bigEndian,
    required int skip,
  }) {
    final List<int> units = <int>[];
    for (int i = skip; i + 1 < bytes.length; i += 2) {
      units.add(
        bigEndian
            ? (bytes[i] << 8) | bytes[i + 1]
            : (bytes[i + 1] << 8) | bytes[i],
      );
    }
    return String.fromCharCodes(units);
  }

  static bool? _guessUtf16WithoutBom(List<int> bytes) {
    final int sample = bytes.length < 400 ? bytes.length : 400;
    if (sample < 4) return null;
    int evenZeros = 0;
    int oddZeros = 0;
    for (int i = 0; i < sample; i++) {
      if (bytes[i] == 0) {
        if (i.isEven) {
          evenZeros++;
        } else {
          oddZeros++;
        }
      }
    }
    final int half = sample ~/ 2;
    if (oddZeros > half * 0.3 && evenZeros == 0) return false;
    if (evenZeros > half * 0.3 && oddZeros == 0) return true;
    return null;
  }

  static List<String> _candidateOrder() {
    final List<String> all = <String>[
      'windows-1252',
      'windows-1256',
      'windows-1251',
      'shift_jis',
      'gbk',
      'euc-kr',
      'big5',
      'windows-1250',
      'windows-1253',
      'windows-1254',
      'windows-1255',
      'windows-1257',
      'windows-1258',
      'windows-874',
      'koi8-r',
    ];
    final String? preferred = switch (L10n.code) {
      'fa' => 'windows-1256',
      'ru' => 'windows-1251',
      'ja' => 'shift_jis',
      _ => null,
    };
    if (preferred != null) {
      all
        ..remove(preferred)
        ..insert(0, preferred);
    }
    return all;
  }

  static String _detectLegacy(List<int> bytes) {
    String best = '';
    double bestScore = -1;
    for (final String name in _candidateOrder()) {
      final String text = _legacy(bytes, name);
      final double score = _score(text);
      if (score > bestScore + 1e-9) {
        bestScore = score;
        best = text;
      }
    }
    return best;
  }

  static String _legacy(List<int> bytes, String name) {
    final String? single = singleByteTables[name];
    if (single != null) {
      final StringBuffer out = StringBuffer();
      for (final int b in bytes) {
        out.write(b < 0x80 ? String.fromCharCode(b) : single[b - 0x80]);
      }
      return out.toString();
    }
    final DoubleByteTable? table = doubleByteTables[name];
    if (table == null) return utf8.decode(bytes, allowMalformed: true);
    final StringBuffer out = StringBuffer();
    int i = 0;
    while (i < bytes.length) {
      final int b = bytes[i];
      if (b < 0x80) {
        out.writeCharCode(b);
        i++;
        continue;
      }
      if (b >= DoubleByteTable.leadMin &&
          b < 0xFF &&
          i + 1 < bytes.length &&
          bytes[i + 1] >= DoubleByteTable.trailMin &&
          bytes[i + 1] < 0xFF) {
        final int index = (b - DoubleByteTable.leadMin) *
                DoubleByteTable.trailCount +
            (bytes[i + 1] - DoubleByteTable.trailMin);
        final String mapped = table.pairs[index];
        if (mapped != '�') {
          out.write(mapped);
          i += 2;
          continue;
        }
      }
      out.write(table.high[b - 0x80]);
      i++;
    }
    return out.toString();
  }

  static double _score(String text) {
    int nonAscii = 0;
    int bad = 0;
    final Map<String, int> scripts = <String, int>{};
    for (final int rune in text.runes) {
      if (rune < 0x80) continue;
      nonAscii++;
      final String? script = _script(rune);
      if (script == null) {
        bad++;
      } else {
        scripts[script] = (scripts[script] ?? 0) + 1;
      }
    }
    if (nonAscii == 0) return 1;
    int top = 0;
    String topScript = '';
    scripts.forEach((String script, int count) {
      if (count > top) {
        top = count;
        topScript = script;
      }
    });
    double score = (top - bad * 2) / nonAscii;
    if (topScript == 'latin' && nonAscii / text.length > 0.4) score *= 0.6;
    return score;
  }

  static String? _script(int r) {
    if (r == 0xFFFD) return null;
    if (r >= 0x80 && r <= 0x9F) return null;
    if (r >= 0xC0 && r <= 0x24F) return 'latin';
    if (r >= 0x1E00 && r <= 0x1EFF) return 'latin';
    if (r >= 0x370 && r <= 0x3FF) return 'greek';
    if (r >= 0x400 && r <= 0x52F) return 'cyrillic';
    if (r >= 0x590 && r <= 0x5FF) return 'hebrew';
    if (r >= 0x600 && r <= 0x6FF) return 'arabic';
    if (r >= 0xE00 && r <= 0xE7F) return 'thai';
    if (r >= 0x3040 && r <= 0x30FF) return 'cjk';
    if (r >= 0x3400 && r <= 0x9FFF) return 'cjk';
    if (r >= 0xAC00 && r <= 0xD7AF) return 'hangul';
    if (r >= 0xFF61 && r <= 0xFF9F) return null;
    if (r >= 0x3000 && r <= 0x303F) return 'cjk';
    if (r >= 0xFF00 && r <= 0xFFEF) return 'cjk';
    if (r >= 0x2010 && r <= 0x2027) return 'punct';
    if (r == 0xA0 || r == 0xAB || r == 0xBB || r == 0xB7) return 'punct';
    return null;
  }
}
