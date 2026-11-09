import 'dart:convert';

import '../mock_data_exception.dart';
import 'json_support.dart';

/// Internal source record, including provenance retained by the service.
class StoreRecord {
  StoreRecord(this.raw, this.sourceName, this.lineNumber) {
    sources.add(SourceLocation(sourceName, lineNumber));
    id = _identifier(raw['shopId'] ?? raw['shopID'], 'shopId');
    if (raw.containsKey('shopId') && raw.containsKey('shopID')) {
      if (_identifier(raw['shopId'], 'shopId') !=
          _identifier(raw['shopID'], 'shopID')) {
        fail('Conflicting shopId and shopID values.', field: 'shopId/shopID');
      }
    }
    final color = raw['background_color'];
    if (color is! String || color.trim().isEmpty) {
      fail('Expected a nonempty string.', field: 'background_color');
    }
    backgroundColor = color;
    name = _optionalString('name');
    slug = _optionalString('slug');
    retailerId = raw['retailer_id'] == null
        ? null
        : _identifier(raw['retailer_id'], 'retailer_id');
    images = _optionalStrings('image');
    tags = _optionalStrings('tags');
  }

  final sources = <SourceLocation>[];
  final Map<String, dynamic> raw;
  final String sourceName;
  final int lineNumber;
  late final String id;
  late final String backgroundColor;
  late final String? name;
  late final String? slug;
  late final String? retailerId;
  late final List<String>? images;
  late final List<String>? tags;

  Never fail(String message, {String? field}) => throw MockDataException(
    sourceName: sourceName,
    lineNumber: lineNumber,
    field: field,
    message: message,
  );

  String _identifier(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is int) return value.toString();
    fail('Expected a nonempty string or integer identifier.', field: field);
  }

  String? _optionalString(String field) {
    final value = raw[field];
    if (value == null || value is String) return value as String?;
    fail('Expected a string or null.', field: field);
  }

  List<String>? _optionalStrings(String field) {
    final value = raw[field];
    if (value == null) return null;
    if (value is! List || value.any((item) => item is! String)) {
      fail('Expected an array of strings or null.', field: field);
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}

List<StoreRecord> parseStoreRecords(String text, String sourceName) {
  final byId = <String, StoreRecord>{};
  final lines = const LineSplitter().convert(text);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.trim().isEmpty) continue;
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      throw MockDataException(
        sourceName: sourceName,
        lineNumber: index + 1,
        message: 'Malformed JSON; expected one complete object per line.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw MockDataException(
        sourceName: sourceName,
        lineNumber: index + 1,
        message: 'Expected a JSON object.',
      );
    }
    final record = StoreRecord(decoded, sourceName, index + 1);
    final existing = byId[record.id];
    if (existing == null) {
      byId[record.id] = record;
    } else if (!_sameJson(existing.raw, record.raw)) {
      record.fail(
        'Conflicting duplicate store ID; first occurrence at line '
        '${existing.lineNumber}.',
        field: 'shopId',
      );
    } else {
      existing.sources.addAll(record.sources);
    }
  }
  return List.unmodifiable(byId.values);
}

bool _sameJson(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && _sameJson(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        Iterable.generate(left.length)
            .every((index) => _sameJson(left[index], right[index]));
  }
  return left == right;
}
