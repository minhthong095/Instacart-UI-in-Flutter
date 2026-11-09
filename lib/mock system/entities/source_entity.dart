import '../data_sources/json_support.dart';

abstract class SourceEntity {
  SourceEntity(JsonRecord record, this.shopId)
    : source = record.source,
      raw = record.raw;
  final String shopId;
  final SourceLocation source;
  final Map<String, Object?> raw;
  Map<String, Object?> toSourceJson() => copyObject(raw);
  Map<String, Object?> toJson() => toSourceJson();
}
