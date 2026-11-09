import '../data_sources/json_support.dart';
import 'source_entity.dart';

class StoreAisle extends SourceEntity {
  StoreAisle.fromRecord(JsonRecord record, {required String shopId})
    : id = record.string('id', nonblank: true),
      name = record.string('name'),
      imageUrl = record.raw.containsKey('imageUrl')
          ? _normalizeImage(record.nullableString('imageUrl'))
          : null,
      super(record, shopId);
  final String id;
  final String name;
  final String? imageUrl;
  Map<String, Object?> get extras =>
      extrasOf(raw, ['id', 'name', 'imageUrl', 'sub']);
  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    ...extras,
  };
}

String? _normalizeImage(String? image) {

  if (image == null) return null;
  final normalized = image.trim().replaceFirst(
    'https://www.instacart.com/image-server/{width=}x{height=}/',
    'https://www.instacart.com/image-server/100x100/',
  );
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  return normalized.startsWith('www.') ? 'https://$normalized' : normalized;
}
