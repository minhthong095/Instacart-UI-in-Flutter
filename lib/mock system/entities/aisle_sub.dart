import '../data_sources/json_support.dart';
import 'aisle_sub_category.dart';
import 'source_entity.dart';

class AisleSub extends SourceEntity {
  AisleSub.fromRecord(
    JsonRecord record, {
    required String shopId,
    required List<AisleSubCategory> categories,
  }) : id = record.string('id', nonblank: true),
       name = record.string('name'),
       slug = record.string('slug'),
       categories = List.unmodifiable(categories),
       super(record, shopId);
  final String id;
  final String name;
  final String slug;
  final List<AisleSubCategory> categories;
  Map<String, Object?> get extras =>
      extrasOf(raw, ['id', 'name', 'slug', 'categories']);
  @override
  Map<String, Object?> toJson() => {
    ...toSourceJson(),
    'categories': categories.map((c) => c.toJson()).toList(),
  };
}
