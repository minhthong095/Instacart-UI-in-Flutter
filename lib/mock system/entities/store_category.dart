import '../data_sources/json_support.dart';
import 'proudct.dart';
import 'resolution_issue.dart';
import 'source_entity.dart';

class StoreCategory extends SourceEntity {
  StoreCategory.fromRecord(
    JsonRecord record, {
    required String shopId,
    required List<Proudct?> items,
    required List<ResolutionIssue> resolutionIssues,
  }) : categoryId = record.integer('categoryId'),
       title = record.string('title'),
       sourceItemIds = record.strings('items'),
       items = List.unmodifiable(items),
       resolutionIssues = List.unmodifiable(resolutionIssues),
       super(record, shopId) {
    if (items.length != sourceItemIds.length) {
      throw ArgumentError('Unaligned hydration.');
    }
  }
  final int categoryId;
  final String title;
  final List<Proudct?> items;
  final List<String> sourceItemIds;
  final List<ResolutionIssue> resolutionIssues;
  Map<String, Object?> get extras =>
      extrasOf(raw, ['categoryId', 'title', 'items']);
  @override
  Map<String, Object?> toJson() => {
    ...toSourceJson(),
    'items': items.map((p) => p?.toJson()).toList(),
  };
}
