/// Kiểm tra response ngay ở biên service, tránh dữ liệu lỗi đi vào widget.
class JsonReader {
  final Map<String, dynamic> json;
  const JsonReader(this.json);

  String string(String key, {String? fallback, bool allowEmpty = false}) {
    final value = json[key] ?? fallback;
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FormatException('Expected string: $key');
    }
    return value;
  }

  String? optionalString(String key) => json[key] == null ? null : string(key);

  int integer(String key, {int min = 0}) {
    final value = json[key];
    if (value is! int || value < min) {
      throw FormatException('Expected integer >= $min: $key');
    }
    return value;
  }

  int? optionalInteger(String key) => json[key] == null ? null : integer(key);

  double number(String key, {double min = 0, double? max}) {
    final value = json[key];
    if (value is! num ||
        !value.isFinite ||
        value < min ||
        (max != null && value > max)) {
      throw FormatException('Invalid number: $key');
    }
    return value.toDouble();
  }

  bool boolean(String key, {bool fallback = false}) {
    final value = json[key] ?? fallback;
    if (value is! bool) throw FormatException('Expected boolean: $key');
    return value;
  }

  List<Map<String, dynamic>> objects(String key) {
    final value = json[key];
    if (value is! List) throw FormatException('Expected array: $key');
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw FormatException('Expected object in: $key');
          }
          return item;
        })
        .toList(growable: false);
  }

  List<String> strings(String key, {bool allowEmpty = true}) {
    final value = json[key];
    if (value is! List ||
        (!allowEmpty && value.isEmpty) ||
        value.any((item) => item is! String || item.trim().isEmpty)) {
      throw FormatException('Expected string array: $key');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}

void requireUniqueIds(Iterable<String> ids, String field) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw FormatException('Duplicate id in $field: $id');
  }
}
