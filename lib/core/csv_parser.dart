abstract class CsvParser {
  static List<List<String>> parse(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var fieldStarted = false;
    final length = input.length;
    for (var i = 0; i < length; i++) {
      final char = input[i];
      if (quoted) {
        if (char == '"') {
          if (i + 1 < length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (char == '"' && !fieldStarted) {
        quoted = true;
        fieldStarted = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
        fieldStarted = false;
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' && i + 1 < length && input[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        fieldStarted = false;
        rows.add(row);
        row = <String>[];
      } else {
        field.write(char);
        fieldStarted = true;
      }
    }
    if (fieldStarted || field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
