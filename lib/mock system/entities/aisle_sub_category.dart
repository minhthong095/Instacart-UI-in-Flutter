import '../data_sources/json_support.dart';
import 'proudct.dart';
import 'resolution_issue.dart';
import 'source_entity.dart';

class AisleSubCategory extends SourceEntity {
  AisleSubCategory.fromRecord(
    JsonRecord record, {
    required String shopId,
    required List<Proudct?> itemIds,
    required List<ResolutionIssue> resolutionIssues,
  }) : id = record.string('id', nonblank: true),
       title = record.nullableString('title'),
       sourceItemIds = record.strings('itemIds'),
       itemIds = List.unmodifiable(itemIds),
       resolutionIssues = List.unmodifiable(resolutionIssues),
       super(record, shopId) {
    if (itemIds.length != sourceItemIds.length) {
      throw ArgumentError('Unaligned hydration.');
    }
  }
  final String id;
  final String? title;
  final List<Proudct?> itemIds;
  final List<String> sourceItemIds;
  final List<ResolutionIssue> resolutionIssues;
  Map<String, Object?> get extras => extrasOf(raw, ['id', 'title', 'itemIds']);
  @override
  Map<String, Object?> toJson() => {
    ...toSourceJson(),
    'itemIds': itemIds.map((p) => p?.toJson()).toList(),
  };
}
