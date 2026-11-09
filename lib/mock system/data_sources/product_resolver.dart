import '../entities/proudct.dart';
import '../entities/resolution_issue.dart';
import 'json_support.dart';
import 'mock_random.dart';

/// One immutable catalog index per exact filename owner. Conflicting identities
/// stay unresolved while unaffected products remain usable for membership joins.
class ProductResolver {
  ProductResolver(
    Iterable<JsonRecord> records,
    this.shopId,
    this.asset,
    int seed,
  ) {
    final rows = <String, List<JsonRecord>>{};
    for (final row in records) {
      final entry = row.withShop(shopId);
      final id = entry.string('id', nonblank: true);
      rows.putIfAbsent(id, () => []).add(entry);
    }
    for (final entry in rows.entries) {
      final matches = entry.value;
      final fake = ProductFakeFields(
        identityRandom(seed, ['product', shopId, entry.key]),
      );
      // Validate each row; malformed rows remain data errors, even in duplicates.
      final products = [
        for (final row in matches)
          Proudct.fromRecord(
            row,
            shopId: shopId,
            f_purchaseHistory: fake.purchaseHistory,
            f_isManyInStock: fake.isManyInStock,
            f_freeText: fake.freeText,
            sources: matches.map((r) => r.source).toList(),
          ),
      ];
      final conflict = matches
          .skip(1)
          .where((r) => !sameJson(matches.first.raw, r.raw));
      if (conflict.isNotEmpty) {
        _conflicts[entry.key] = conflict.first.source;
      } else {
        _resolved[entry.key] = products.first;
      }
      if (matches.length > 1) {
        _duplicates[entry.key] = List.unmodifiable(
          matches.map((r) => r.source),
        );
      }
    }
  }

  final String shopId;
  final String asset;
  final _resolved = <String, Proudct>{};
  final _conflicts = <String, SourceLocation>{};
  final _duplicates = <String, List<SourceLocation>>{};

  List<Proudct> get resolved => List.unmodifiable(_resolved.values);

  ResolutionIssue? issueFor(String id, SourceLocation request) {
    final matches = _duplicates[id] ?? const <SourceLocation>[];
    final code = _conflicts.containsKey(id)
        ? 'conflicting_product_records'
        : !_resolved.containsKey(id)
        ? 'missing_product_id'
        : matches.isNotEmpty
        ? 'duplicate_identical_product'
        : null;
    return code == null
        ? null
        : ResolutionIssue(code, request, productId: id, matches: matches);
  }

  Proudct? resolve(String id, SourceLocation request, DiagnosticSink report) {
    final issue = issueFor(id, request);
    if (issue != null) report(issue);
    return _resolved[id];
  }

  void reportCatalogIssues(DiagnosticSink report) {
    for (final id in _duplicates.keys) {
      final issue = issueFor(id, _duplicates[id]!.first);
      if (issue != null) report(issue);
    }
  }

  /// Complete-catalog consumers cannot represent ambiguous records as products.
  List<Proudct> completeCatalog(DiagnosticSink report) {
    reportCatalogIssues(report);
    if (_conflicts.isNotEmpty) {
      final conflict = _conflicts.entries.reduce(
        (a, b) => a.value.line < b.value.line ? a : b,
      );
      conflict.value.fail(
        'Conflicting duplicate product ID ${conflict.key}; '
        'first occurrence at line ${_duplicates[conflict.key]!.first.line}.',
        field: 'id',
      );
    }
    return resolved;
  }
}
