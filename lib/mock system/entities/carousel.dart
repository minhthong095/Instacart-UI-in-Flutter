import '../data_sources/json_support.dart';

class Carousel {
  Carousel.fromRecord(
    JsonRecord record, {
    required this.shopId,
    List<SourceLocation>? sources,
  }) : sources = List.unmodifiable(sources ?? [record.source]),
       id = record.string('id', nonblank: true),
       name = record.string('name'),
       image = _normalizeImage(record.string('image')),
       slug = record.string('slug'),
       source = record.source,
       _raw = record.raw;

  final List<SourceLocation> sources;
  final String shopId;
  final String id;
  final String name;
  final String image;
  final String slug;
  final SourceLocation source;
  final Map<String, Object?> _raw;

  Map<String, Object?> get extras =>
      extrasOf(_raw, ['id', 'name', 'image', 'slug']);

  /// Exact source entry payload; [shopId] and [source] are association metadata.
  Map<String, Object?> toSourceJson() => copyObject(_raw);
  Map<String, Object?> toJson() => copyObject(_raw);
}

String _normalizeImage(String image) {
  final normalized = image.trim().replaceFirst(
      'https://www.instacart.com/image-server/{width=}x{height=}/',
      '',
    );
  if (normalized.startsWith('http://') ||
      normalized.startsWith('https://')) {
    return normalized;
  }
  return normalized.startsWith('www.') ? 'https://$normalized' : normalized;
}
