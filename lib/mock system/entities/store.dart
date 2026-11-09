// Required API field names distinguish fake content from source metadata.
// ignore_for_file: non_constant_identifier_names

import '../data_sources/json_support.dart';

class Store {
  Store({
    Map<String, Object?> sourceJson = const {},
    List<SourceLocation> sources = const [],
    required this.id,
    required this.backgroundColor,
    required this.f_priceRange,
    required this.f_deliveryBy,
    required this.f_locationRange,
    required List<String>? f_tags,
    this.name,
    this.slug,
    this.retailerId,
    List<String>? images,
    List<String>? tags,
  }) : _raw = freezeObject(sourceJson),
       sources = List.unmodifiable(sources),
       f_tags = f_tags == null ? null : List.unmodifiable(f_tags),
       images = images == null ? null : List.unmodifiable(images),
       tags = tags == null ? null : List.unmodifiable(tags);

  final Map<String, Object?> _raw;
  final List<SourceLocation> sources;
  Map<String, Object?> get extras => extrasOf(_raw, [
    'shopId',
    'shopID',
    'background_color',
    'name',
    'slug',
    'retailer_id',
    'image',
    'tags',
  ]);
  Map<String, Object?> toSourceJson() => copyObject(_raw);

  final String id;
  final String backgroundColor;
  final String? f_priceRange;
  final String? f_deliveryBy;
  final double f_locationRange;
  final List<String>? f_tags;
  final String? name;
  final String? slug;
  final String? retailerId;
  final List<String>? images;
  final List<String>? tags;

  Map<String, Object?> toJson() => {
    'id': id,
    'backgroundColor': backgroundColor,
    'f_priceRange': f_priceRange,
    'f_deliveryBy': f_deliveryBy,
    'f_locationRange': f_locationRange,
    'f_tags': f_tags?.toList(),
    'name': name,
    'slug': slug,
    'retailerId': retailerId,
    'images': images?.toList(),
    'tags': tags?.toList(),
  };
}
