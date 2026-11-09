// ignore_for_file: non_constant_identifier_names
import '../data_sources/json_support.dart';

class ProductImage {
  ProductImage.fromRecord(JsonRecord record)
    : url = record.string('url'),
      templateUrl = record.string('templateUrl'),
      _raw = record.raw;

  final String url;
  final String templateUrl;
  final Map<String, Object?> _raw;

  Map<String, Object?> get extras => extrasOf(_raw, ['url', 'templateUrl']);
  Map<String, Object?> toJson() => copyObject(_raw);
}

class ProductSection {
  ProductSection.fromRecord(JsonRecord record)
    : headerString = record.string('headerString'),
      bodyString = record.string('bodyString'),
      _raw = record.raw;

  final String headerString;
  final String bodyString;
  final Map<String, Object?> _raw;

  Map<String, Object?> get extras =>
      extrasOf(_raw, ['headerString', 'bodyString']);
  Map<String, Object?> toJson() => copyObject(_raw);
}

/// The API's original spelling is intentional. Source keys remain unchanged.
class Proudct {
  Proudct.fromRecord(
    JsonRecord record, {
    required this.shopId,
    this.f_purchaseHistory,
    this.f_isManyInStock = false,
    this.f_freeText,
    List<SourceLocation>? sources,
  }) : sources = List.unmodifiable(sources ?? [record.source]),
       id = record.string('id', nonblank: true),
       variants = _variants(record),
       images = List.unmodifiable(
         record.objects('images').map(ProductImage.fromRecord),
       ),
       sections = List.unmodifiable(
         record.objects('sections').map(ProductSection.fromRecord),
       ),
       name = record.string('name'),
       isNutritionAvailable = record.boolean('isNutritionAvailable'),
       proudctSlug = record.string('proudctSlug'),
       pricePerUnit = _pricePerUnit(record),
       fullPrice = record.nullableString('fullPrice'),
       pricingUnit = record.nullableString('pricingUnit'),
       price = record.string('price'),
       isLoyaltyProgramAvailbale = record.boolean('isLoyaltyProgramAvailbale'),
       offerLabelString = record.nullableString('offerLabelString'),
       source = record.source,
       _raw = record.raw;

  final int? f_purchaseHistory;
  final bool f_isManyInStock;
  final String? f_freeText;
  final List<SourceLocation> sources;
  final String shopId;
  final String id;

  /// Exact related-product ID strings; full files contain nonempty lists too.
  final List<String>? variants;
  final List<ProductImage> images;
  final List<ProductSection> sections;
  final String name;
  final bool isNutritionAvailable;
  final String proudctSlug;

  /// Currently null in all supplied products; a non-null schema is unspecified.
  final JsonValue pricePerUnit;
  final String? fullPrice;
  final String? pricingUnit;
  final String price;
  final bool isLoyaltyProgramAvailbale;
  final String? offerLabelString;
  final SourceLocation source;
  final Map<String, Object?> _raw;

  static List<String>? _variants(JsonRecord record) {
    record.requireKey('variants');
    return record.raw['variants'] == null ? null : record.strings('variants');
  }

  static JsonValue _pricePerUnit(JsonRecord record) {
    record.requireKey('pricePerUnit');
    return record.raw['pricePerUnit'];
  }

  Map<String, Object?> get extras => extrasOf(_raw, const [
    'id',
    'variants',
    'images',
    'sections',
    'name',
    'isNutritionAvailable',
    'proudctSlug',
    'pricePerUnit',
    'fullPrice',
    'pricingUnit',
    'price',
    'isLoyaltyProgramAvailbale',
    'offerLabelString',
  ]);

  /// Lossless detached source payload, excluding ownership/provenance metadata.
  Map<String, Object?> toSourceJson() => copyObject(_raw);
  Map<String, Object?> toJson() => {
    ...toSourceJson(),
    'f_purchaseHistory': f_purchaseHistory,
    'f_isManyInStock': f_isManyInStock,
    'f_freeText': f_freeText,
  };
}
