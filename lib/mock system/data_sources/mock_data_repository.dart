import 'dart:math';

import '../entities/aisle_sub.dart';
import '../entities/aisle_sub_category.dart';
import '../entities/carousel.dart';
import '../entities/proudct.dart';
import '../entities/product_display.dart';
import '../entities/resolution_issue.dart';
import '../entities/store.dart';
import '../entities/store_aisle.dart';
import '../entities/store_aisle_detail.dart';
import '../entities/store_category.dart';
import '../mock_config.dart';
import '../mock_data_exception.dart';
import 'dataset_inventory.dart';
import 'json_support.dart';
import 'mock_random.dart';
import 'mock_text_data_source.dart';
import 'product_resolver.dart';
import 'store_data_source.dart';
import 'store_parser.dart';

/// All six service facades share this repository. In-flight work and failures
/// are cached independently. Expanded membership responses are never cached.
class MockDataRepository {
  MockDataRepository({
    int? seed,
    StoreDataSource? storeDataSource,
    MockTextDataSource? textDataSource,
    Set<String>? assetInventory,
    DiagnosticSink? diagnosticSink,
  }) : _seed = seed ?? Random().nextInt(0x7fffffff),
       _textSource = textDataSource ?? AssetMockTextDataSource(),
       _storeSource = storeDataSource,
       _inventory = Set.unmodifiable(
         assetInventory ??
             (textDataSource is MockAssetInventory
                 ? (textDataSource as MockAssetInventory).availableAssets
                 : bundledMockAssets),
       ),
       _sink = diagnosticSink;

  final int _seed;
  late final Random _random = Random(_seed);
  final MockTextDataSource _textSource;
  final StoreDataSource? _storeSource;
  final Set<String> _inventory;
  final DiagnosticSink? _sink;
  Future<List<Store>?>? _storeInitialization;
  Future<Map<String, List<Carousel>>?>? _carouselInitialization;
  Future<Map<String, JsonRecord>?>? _categoryInitialization;
  Future<Map<String, JsonRecord>?>? _hierarchyInitialization;
  final _productInitializations = <String, Future<ProductResolver?>>{};
  Map<String, Store> _storesById = const {};

  void _report(ResolutionIssue issue) => _sink?.call(issue);
  void _missing(
    String code,
    String asset, {
    String? shopId,
    String? id,
    SourceLocation? source,
  }) => _report(
    ResolutionIssue(
      code,
      source ?? SourceLocation(asset, 0, shopId: shopId),
      productId: id,
    ),
  );

  Future<String?> _text(
    String asset, {
    String? shopId,
    bool reportAbsence = true,
  }) async {
    if (!_inventory.contains(asset)) {
      if (reportAbsence) {
        _missing(
          asset.startsWith(MockConfig.productAssetDirectory)
              ? 'missing_product_file'
              : 'missing_source',
          asset,
          shopId: shopId,
        );
      }
      return null;
    }
    try {
      return await _textSource.loadText(asset);
    } catch (error) {
      throw MockDataException(
        sourceName: asset,
        message:
            '${shopId == null ? '' : 'Shop $shopId: '}Unable to load inventoried data. '
            'Check runtime I/O and pubspec.yaml registration. $error',
      );
    }
  }

  Future<List<Store>?> stores() => _storeInitialization ??= _loadStores();

  Future<List<Store>?> _loadStores() async {
    final source = _storeSource;
    final String? text;
    final asset = source?.sourceName ?? MockConfig.storeAsset;
    if (source == null) {
      text = await _text(asset);
    } else {
      try {
        text = await source.loadStoresText();
      } on MockDataException {
        rethrow;
      } catch (_) {
        throw MockDataException(
          sourceName: asset,
          message: 'Unable to load store data.',
        );
      }
    }
    if (text == null) return null;
    final records = parseStoreRecords(text, asset);
    final result = List<Store>.unmodifiable(
      records.map((record) {
        if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(record.id)) {
          record.fail('Unsafe shop identifier.', field: 'shopId');
        }
        if (record.sources.length > 1) {
          _report(
            ResolutionIssue(
              'duplicate_identical_store',
              record.sources.first.child('shopId', shopId: record.id),
              matches: record.sources,
            ),
          );
        }
        return _enrich(record);
      }),
    );
    _storesById = Map.unmodifiable({
      for (final store in result) store.id: store,
    });
    return result;
  }

  Store _enrich(StoreRecord record) {
    final random = identityRandom(_seed, ['store', record.id]);
    bool isNull() => random.nextInt(MockConfig.nullableOneIn) == 0;
    final price =
        MockConfig.priceRanges[random.nextInt(MockConfig.priceRanges.length)];
    String? delivery;
    if (!isNull()) {
      delivery =
          '${random.nextInt(MockConfig.hoursPerDay).toString().padLeft(2, '0')}:'
          '${random.nextInt(MockConfig.minutesPerHour).toString().padLeft(2, '0')}';
    }
    final distance =
        (MockConfig.minDistanceTenths +
            random.nextInt(
              MockConfig.maxDistanceTenths - MockConfig.minDistanceTenths + 1,
            )) /
        10;
    List<String>? tags;
    if (!isNull()) {
      final pool = MockConfig.allowedFakeTags.toList()..shuffle(random);
      tags = pool.take(1 + random.nextInt(MockConfig.maxFakeTags)).toList();
    }
    return Store(
      id: record.id,
      backgroundColor: record.backgroundColor,
      name: record.name,
      slug: record.slug,
      retailerId: record.retailerId,
      images: record.images,
      tags: record.tags,
      sourceJson: record.raw,
      sources: record.sources,
      f_priceRange: price,
      f_deliveryBy: delivery,
      f_locationRange: distance,
      f_tags: tags,
    );
  }

  /// Unknown well-formed IDs represent unavailable records. Malformed IDs never
  /// become path components; lookup is always constrained to loaded store IDs.
  Future<Store?> requireStore(String suppliedId) async {
    final id = suppliedId.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw ArgumentError.value(
        suppliedId,
        'storeId',
        'Invalid store identifier.',
      );
    }
    await stores();
    final store = _storesById[id];
    if (store == null) {
      _missing('missing_store', MockConfig.storeAsset, shopId: id);
    }
    return store;
  }

  static void validateId(String id, String argument) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, argument, 'Must not be blank.');
    }
  }

  List<T> sample<T>(List<T> pool, int count, {bool pad = true}) {
    if (count <= 0) {
      throw ArgumentError.value(count, 'count', 'Must be positive.');
    }
    if (pool.isEmpty) return List<T>.unmodifiable([]);
    final shuffled = pool.toList()..shuffle(_random);
    final result = shuffled.take(count).toList();
    while (pad && result.length < count) {
      result.add(pool[_random.nextInt(pool.length)]);
    }
    return List.unmodifiable(result);
  }

  Future<List<Store>?> sampleStores(int count) async {
    final pool = await stores();
    return pool == null ? null : sample(pool, count);
  }

  String nextServiceLabel() =>
      MockConfig.serviceLabels[_random.nextInt(
        MockConfig.serviceLabels.length,
      )];

  Future<Map<String, JsonRecord>?> _shopRecords(String asset) async {
    final text = await _text(asset);
    if (text == null) return null;
    final originals = <String, JsonRecord>{};
    for (final raw in parseJsonLines(text, asset)) {
      final shopId = raw.shopId;
      final record = raw.withShop(shopId);
      final existing = originals[shopId];
      if (existing != null) {
        if (!sameJson(existing.raw, record.raw)) {
          record.source.fail(
            'Conflicting duplicate shop-associated record; '
            'first occurrence at line ${existing.source.line}.',
            field: 'shopId/shopID',
          );
        }
        _report(
          ResolutionIssue(
            'duplicate_identical_record',
            record.source,
            matches: [existing.source, record.source],
          ),
        );
      } else {
        originals[shopId] = record;
      }
    }
    return Map.unmodifiable(originals);
  }

  Future<Map<String, List<Carousel>>?> _carouselRecords() =>
      _carouselInitialization ??= _loadCarousels();
  Future<Map<String, List<Carousel>>?> _loadCarousels() async {
    final text = await _text(MockConfig.carouselAsset);
    if (text == null) return null;
    final byShop = <String, Map<String, List<JsonRecord>>>{};
    for (final record in parseJsonLines(text, MockConfig.carouselAsset)) {
      final shopId = record.shopId;
      final byId = byShop.putIfAbsent(shopId, () => {});
      for (final entry in record.objects('carousel', shopId: shopId)) {
        final id = entry.string('id', nonblank: true);
        final matches = byId.putIfAbsent(id, () => []);
        if (matches.isNotEmpty && !sameJson(matches.first.raw, entry.raw)) {
          entry.source.fail(
            'Conflicting duplicate carousel ID $id; '
            'first occurrence at line ${matches.first.source.line}.',
            field: 'id',
          );
        }
        matches.add(entry);
      }
    }
    return Map.unmodifiable({
      for (final shop in byShop.entries)
        shop.key: List<Carousel>.unmodifiable(
          shop.value.values.map((matches) {
            if (matches.length > 1) {
              _report(
                ResolutionIssue(
                  'duplicate_identical_carousel',
                  matches.first.source,
                  matches: matches.map((r) => r.source).toList(),
                ),
              );
            }
            return Carousel.fromRecord(
              matches.first,
              shopId: shop.key,
              sources: matches.map((r) => r.source).toList(),
            );
          }),
        ),
    });
  }

  Future<List<Carousel>?> carousels() async {
    final records = await _carouselRecords();
    return records == null
        ? null
        : List.unmodifiable(records.values.expand((v) => v));
  }

  Future<List<Carousel>?> sampleCarousels() async {
    final pool = await carousels();
    return pool == null ? null : sample(pool, MockConfig.carouselHeaderCount);
  }

  Future<List<Carousel>?> carouselsForStore(String storeId) async {
    final store = await requireStore(storeId);
    if (store == null) return null;
    final records = await _carouselRecords();
    final entries = records?[store.id];
    if (entries == null) {
      _missing(
        records == null ? 'missing_source' : 'missing_carousel_record',
        MockConfig.carouselAsset,
        shopId: store.id,
      );
    }
    return entries;
  }

  Future<ProductResolver?> _products(String shopId) async {
    final asset = '${MockConfig.productAssetDirectory}/$shopId.jsonl';
    final resolver = await _productInitializations.putIfAbsent(
      shopId,
      () async {
        final text = await _text(asset, shopId: shopId, reportAbsence: false);
        return text == null
            ? null
            : ProductResolver(
                parseJsonLines(text, asset),
                shopId,
                asset,
                _seed,
              );
      },
    );
    if (resolver == null) {
      _missing('missing_product_file', asset, shopId: shopId);
    }
    return resolver;
  }

  Future<List<Proudct>?> productsForStore(String storeId) async {
    final store = await requireStore(storeId);
    if (store == null) return null;
    return (await _products(store.id))?.completeCatalog(_report);
  }

  Future<Proudct?> product(String storeId, String productId) async {
    validateId(productId, 'productId');
    final store = await requireStore(storeId);
    if (store == null) return null;
    final resolver = await _products(store.id);
    return resolver?.resolve(
      productId,
      SourceLocation(
        '${MockConfig.productAssetDirectory}/${store.id}.jsonl',
        0,
        shopId: store.id,
        path: 'product[$productId]',
      ),
      _report,
    );
  }

  Future<List<ProductDisplay>?> productDisplays(
    String storeId,
    String productId,
  ) async {
    final anchor = await product(storeId, productId);
    if (anchor == null) return null;
    final resolver = await _products(anchor.shopId);
    if (resolver == null) return null;
    resolver.reportCatalogIssues(_report);
    final candidates = resolver.resolved
        .where((p) => p.id != productId)
        .toList();
    if (candidates.isEmpty) return const [];
    final labels = sample(
      MockConfig.productDisplayLabels,
      1 + _random.nextInt(MockConfig.maxRecommendationGroups),
      pad: false,
    );
    return List.unmodifiable([
      for (final label in labels)
        ProductDisplay(
          f_label: label,
          proudcts: sample(
            candidates,
            MockConfig.recommendationLimit,
            pad: false,
          ),
        ),
    ]);
  }

  Future<Map<String, JsonRecord>?> _categories() =>
      _categoryInitialization ??= _shopRecords(MockConfig.categoryAsset);
  Future<Map<String, JsonRecord>?> _hierarchy() =>
      _hierarchyInitialization ??= _shopRecords(MockConfig.hierarchyAsset);

  ({List<Proudct?> products, List<ResolutionIssue> issues}) _hydrate(
    JsonRecord record,
    String key,
    String shopId,
    ProductResolver? resolver,
  ) {
    final ids = record.strings(key);
    final products = <Proudct?>[];
    final issues = <ResolutionIssue>[];
    for (var i = 0; i < ids.length; i++) {
      final source = record.source.child('$key[$i]', shopId: shopId);
      void report(ResolutionIssue issue) {
        issues.add(issue);
        _report(issue);
      }

      if (resolver == null) {
        report(
          ResolutionIssue(
            'missing_product_file',
            source,
            productId: ids[i],
            matches: [
              SourceLocation(
                '${MockConfig.productAssetDirectory}/$shopId.jsonl',
                0,
                shopId: shopId,
              ),
            ],
          ),
        );
        products.add(null);
      } else {
        products.add(resolver.resolve(ids[i], source, report));
      }
    }
    return (products: products, issues: issues);
  }

  Future<List<StoreCategory>?> categoriesForStore(String storeId) async {
    final store = await requireStore(storeId);
    if (store == null) return null;
    final records = await _categories();
    final record = records?[store.id];
    if (record == null) {
      _missing(
        records == null ? 'missing_source' : 'missing_category_record',
        MockConfig.categoryAsset,
        shopId: store.id,
      );
      return null;
    }
    final categories = record.objects('productCategory', shopId: store.id);
    if (categories.isEmpty) return const [];
    final resolver = await _products(store.id);
    return List.unmodifiable(
      categories.map((entry) {
        final hydrated = _hydrate(entry, 'items', store.id, resolver);
        return StoreCategory.fromRecord(
          entry,
          shopId: store.id,
          items: hydrated.products,
          resolutionIssues: hydrated.issues,
        );
      }),
    );
  }

  Future<List<JsonRecord>?> _aisles(String storeId) async {
    final store = await requireStore(storeId);
    if (store == null) return null;
    final records = await _hierarchy();
    final record = records?[store.id];
    if (record == null) {
      _missing(
        records == null ? 'missing_source' : 'missing_hierarchy_record',
        MockConfig.hierarchyAsset,
        shopId: store.id,
      );
      return null;
    }
    return record.objects('aisles', shopId: store.id);
  }

  Future<List<StoreAisle>?> aislesForStore(String storeId) async {
    final entries = await _aisles(storeId);
    return entries == null
        ? null
        : List.unmodifiable(
            entries.map(
              (entry) =>
                  StoreAisle.fromRecord(entry, shopId: entry.source.shopId!),
            ),
          );
  }

  Future<StoreAisleDetail?> aisleDetail(String storeId, String aisleId) async {
    validateId(aisleId, 'aisleId');
    final entries = await _aisles(storeId);
    if (entries == null) return null;
    final matches = entries
        .where((entry) => entry.string('id', nonblank: true) == aisleId)
        .toList();
    if (matches.length != 1) {
      _missing(
        matches.isEmpty ? 'missing_aisle' : 'ambiguous_aisle',
        MockConfig.hierarchyAsset,
        shopId: storeId.trim(),
        source: matches.firstOrNull?.source,
      );
      return null;
    }
    final entry = matches.single;
    final shopId = entry.source.shopId!;
    final resolver = await _products(shopId);
    final subs = [
      for (final sub in entry.objects('sub'))
        AisleSub.fromRecord(
          sub,
          shopId: shopId,
          categories: [
            for (final category in sub.objects('categories'))
              _aisleCategory(category, shopId, resolver),
          ],
        ),
    ];
    return StoreAisleDetail.fromRecord(entry, shopId: shopId, sub: subs);
  }

  AisleSubCategory _aisleCategory(
    JsonRecord entry,
    String shopId,
    ProductResolver? resolver,
  ) {
    final hydrated = _hydrate(entry, 'itemIds', shopId, resolver);
    return AisleSubCategory.fromRecord(
      entry,
      shopId: shopId,
      itemIds: hydrated.products,
      resolutionIssues: hydrated.issues,
    );
  }
}
