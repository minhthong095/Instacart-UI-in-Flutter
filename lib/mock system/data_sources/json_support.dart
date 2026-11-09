import 'dart:convert';

import '../mock_data_exception.dart';

/// JSON scalars, lists and string-keyed maps only. Collections are deeply frozen.
/// Used for fields whose non-null schema is not established by this dataset.
typedef JsonValue = Object?;

class SourceLocation {
  const SourceLocation(this.asset, this.line, {this.shopId, this.path = ''});

  final String asset;
  final int line;
  final String? shopId;
  final String path;

  SourceLocation child(String key, {String? shopId}) => SourceLocation(
    asset,
    line,
    shopId: shopId ?? this.shopId,
    path: path.isEmpty ? key : '$path.$key',
  );

  Never fail(String message, {String? field}) => throw MockDataException(
    sourceName: asset,
    lineNumber: line,
    field: [if (path.isNotEmpty) path, ?field].join('.'),
    message: '${shopId == null ? '' : 'Shop $shopId: '}$message',
  );
}

Object? freezeJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      value.map((key, value) => MapEntry(key as String, freezeJson(value))),
    );
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(freezeJson));
  return value;
}

Map<String, Object?> freezeObject(Map<String, Object?> value) =>
    freezeJson(value)! as Map<String, Object?>;

Object? copyJson(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key as String, copyJson(value)));
  }
  if (value is List) return value.map(copyJson).toList();
  return value;
}

Map<String, Object?> copyObject(Map<String, Object?> value) =>
    copyJson(value)! as Map<String, Object?>;

Map<String, Object?> extrasOf(
  Map<String, Object?> raw,
  Iterable<String> known,
) =>
    Map.unmodifiable(Map.of(raw)..removeWhere((key, _) => known.contains(key)));

bool sameJson(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && sameJson(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        Iterable.generate(left.length)
            .every((i) => sameJson(left[i], right[i]));
  }
  return left == right;
}

class JsonRecord {
  JsonRecord(Map<String, Object?> raw, this.source) : raw = freezeObject(raw);

  JsonRecord._frozen(this.raw, this.source);

  final Map<String, Object?> raw;
  final SourceLocation source;

  JsonRecord withShop(String shopId) => JsonRecord._frozen(
    raw,
    SourceLocation(
      source.asset,
      source.line,
      shopId: shopId,
      path: source.path,
    ),
  );

  String string(String key, {bool nonblank = false}) {
    final value = raw[key];
    if (value is! String || (nonblank && value.trim().isEmpty)) {
      source.fail('Expected ${nonblank ? 'nonblank ' : ''}string.', field: key);
    }
    return value;
  }

  String? nullableString(String key) {
    requireKey(key);
    final value = raw[key];
    if (value == null || value is String) return value as String?;
    source.fail('Expected string or null.', field: key);
  }

  void requireKey(String key) {
    if (!raw.containsKey(key)) {
      source.fail('Missing required field.', field: key);
    }
  }

  bool boolean(String key) {
    final value = raw[key];
    if (value is bool) return value;
    source.fail('Expected boolean.', field: key);
  }

  int integer(String key) {
    final value = raw[key];
    if (value is int) return value;
    source.fail('Expected integer.', field: key);
  }

  String identifier(String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is int) return value.toString();
    source.fail('Expected nonblank string or integer identifier.', field: key);
  }

  String get shopId {
    final key = raw.containsKey('shopId') ? 'shopId' : 'shopID';
    final id = identifier(key);
    if (raw.containsKey('shopId') &&
        raw.containsKey('shopID') &&
        id != identifier('shopID')) {
      source.fail('Conflicting shopId and shopID.', field: 'shopId/shopID');
    }
    return id;
  }

  List<Object?> array(String key) {
    final value = raw[key];
    if (value is List<Object?>) return value;
    source.fail('Expected array.', field: key);
  }

  List<String> strings(String key) {
    final value = array(key);
    if (value.any((item) => item is! String)) {
      source.fail('Expected array of strings.', field: key);
    }
    return List.unmodifiable(value.cast<String>());
  }

  List<JsonRecord> objects(String key, {String? shopId}) {
    final values = array(key);
    return List.generate(values.length, (i) {
      final source = this.source.child('$key[$i]', shopId: shopId);
      final value = values[i];
      if (value is! Map<String, Object?>) {
        source.fail('Expected JSON object.');
      }
      return JsonRecord._frozen(value, source);
    });
  }
}

Iterable<JsonRecord> parseJsonLines(String text, String asset) sync* {
  var lineNumber = 0;
  for (final line in LineSplitter.split(text)) {
    lineNumber++;
    if (line.trim().isEmpty) continue;
    final source = SourceLocation(asset, lineNumber);
    final Object? value;
    try {
      value = jsonDecode(line);
    } on FormatException {
      source.fail(
        'Malformed JSON; expected one object per nonblank JSONL line.',
      );
    }
    if (value is! Map<String, Object?>) source.fail('Expected JSON object.');
    yield JsonRecord(value, source);
  }
}
