// Tests are kept under the requested mock-system output directory.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../mock_system.dart';
import 'mock_services_test.dart' as fixture;

String catalog(String id) => '${MockConfig.productAssetDirectory}/$id.jsonl';
Map<String, Object?> category({
  List<String> ids = const ['shared', 'missing', 'shared'],
}) => {
  'id': 'repeated',
  'title': null,
  'itemIds': ids,
  'future': {
    'keep': [null, 1],
  },
};
Map<String, Object?> aisle({String id = 'aisle', Object? image}) => {
  'id': id,
  'name': 'Source aisle',
  'imageUrl': image,
  'sub': [
    for (final name in ['first', 'second'])
      {
        'id': 'same-sub-id',
        'name': name,
        'slug': 'raw-$name',
        'categories': [category(), category(ids: [])],
      },
  ],
  'extra': [
    null,
    {'unknown': true},
  ],
};
Map<String, String> data() =>
    fixture.fixtures()
      ..[MockConfig.hierarchyAsset] = fixture.lines([
        {
          'shopID': 'a',
          'aisles': [aisle()],
        },
        {'shopID': 'b', 'aisles': []},
      ]);
MockDataRepository repo(
  Map<String, String> assets, {
  int seed = 42,
  DiagnosticSink? sink,
}) => MockDataRepository(
  seed: seed,
  textDataSource: InMemoryMockTextDataSource(assets),
  diagnosticSink: sink,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('central label cardinalities and both distinct length constraints', () {
    for (final entry in [
      (MockConfig.displayLabels, 7, 0),
      (MockConfig.serviceLabels, 100, 1),
      (MockConfig.productDisplayLabels, 100, 5),
      (MockConfig.foodLabels, 20, 2),
    ]) {
      expect(entry.$1.toSet(), hasLength(entry.$2));
      expect(entry.$1, hasLength(entry.$2));
      expect(entry.$1.every((s) => s.trim().isNotEmpty), isTrue);
      if (entry.$3 == 1) {
        expect(entry.$1.every((s) => s.length <= 5), isTrue);
      }
      if (entry.$3 > 1) {
        expect(
          entry.$1.every((s) => s.split(RegExp(r'\s+')).length <= entry.$3),
          isTrue,
        );
      }
    }
    expect(
      MockConfig.productDisplayLabels,
      containsAll([
        'Frequently bought together',
        'Often Bought With',
        'Items to add next',
        'Customers also considered',
      ]),
    );
  });

  test('exact same-shop lookup, missing identities and validation; no prefix joins', () async {
    final assets = data();
    assets[catalog('a')] = fixture.lines([fixture.product('b-prefix')]);
    assets[catalog('b')] = fixture.lines([
      fixture.product('b-prefix')..['name'] = 'Shop B',
    ]);
    final ProductService service = MockProductService(repository: repo(assets));
    final a = await service.getProduct(' a ', 'b-prefix');
    final b = await service.getProduct('b', 'b-prefix');
    expect(a?.shopId, 'a');
    expect(b?.shopId, 'b');
    expect(a?.name, 'Source name');
    expect(b?.name, 'Shop B');
    expect(await service.getProduct('a', ' b-prefix '), isNull);
    expect(await service.getProduct('unknown', 'b-prefix'), isNull);
    expect(await service.getProductDisplay('a', 'absent'), isNull);
    await expectLater(service.getProduct('a', ' '), throwsArgumentError);
    await expectLater(
      service.getProduct('../a', 'b-prefix'),
      throwsArgumentError,
    );
  });

  test('flat hydration preserves every original ID and nullable slot without hierarchy', () async {
    final assets = data()..remove(MockConfig.hierarchyAsset);
    assets[MockConfig.categoryAsset] = fixture.lines([
      fixture.membership(
        'a',
        entries: [
          {
            'categoryId': 1,
            'title': 'Source title',
            'items': ['shared', 'missing', 'shared'],
            'future': [null],
          },
          {'categoryId': 1, 'title': 'Repeated category', 'items': []},
        ],
      ),
    ]);
    final categories = (await MockStorePage(repository: repo(assets))
        .getCategories('a'))!;
    expect(categories, hasLength(2));
    final first = categories.first;
    expect(first.items.map((p) => p?.id), ['shared', null, 'shared']);
    expect(identical(first.items[0], first.items[2]), isTrue);
    expect(first.sourceItemIds, ['shared', 'missing', 'shared']);
    expect(first.resolutionIssues.single.code, 'missing_product_id');
    expect(
      first.resolutionIssues.single.source.path,
      'productCategory[0].items[1]',
    );
    expect(first.toSourceJson(), {
      'categoryId': 1,
      'title': 'Source title',
      'items': ['shared', 'missing', 'shared'],
      'future': [null],
    });
    expect(() => first.sourceItemIds.clear(), throwsUnsupportedError);
    expect(() => first.resolutionIssues.clear(), throwsUnsupportedError);
  });

  test(
    'hierarchy summaries are lazy and preserve nullable/absent image keys',
    () async {
      final assets = data()
        ..remove(catalog('a'))
        ..remove(MockConfig.categoryAsset);
      final raw = aisle()..remove('imageUrl');
      assets[MockConfig.hierarchyAsset] = fixture.lines([
        {
          'shopID': 'a',
          'aisles': [raw, aisle(id: 'two', image: 'url/{width=}/{height=}')],
        },
      ]);
      final source = fixture.CountingTextSource(assets);
      final repository = MockDataRepository(seed: 42, textDataSource: source);
      final ShopByAisleService service = MockShopByAisleService(
        repository: repository,
      );
      final summaries = (await service.getAisles('a'))!;
      expect(summaries.map((s) => s.id), ['aisle', 'two']);
      expect(summaries.first.imageUrl, isNull);
      expect(summaries.first.toSourceJson().containsKey('imageUrl'), isFalse);
      expect(summaries.last.imageUrl, 'url/{width=}/{height=}');
      expect(source.loads.keys.toSet(), {
        MockConfig.storeAsset,
        MockConfig.hierarchyAsset,
      });
    },
  );

  test('selected aisle detail preserves parents, empty arrays, null titles, extras, paths', () async {
    final repository = repo(data()..remove(MockConfig.categoryAsset));
    final AisleDetailService service = MockAisleDetailService(
      repository: repository,
    );
    final detail = (await service.getAisleDetail('a', 'aisle'))!;
    expect(detail.toSourceJson(), aisle());
    expect(detail.imageUrl, isNull);
    expect(detail.sub.map((s) => s.id), ['same-sub-id', 'same-sub-id']);
    expect(detail.sub, hasLength(2));
    for (var index = 0; index < detail.sub.length; index++) {
      final categories = detail.sub[index].categories;
      expect(categories, hasLength(2));
      expect(categories.last.itemIds, isEmpty);
      final category = categories.first;
      expect(category.title, isNull);
      expect(category.itemIds.map((p) => p?.id), ['shared', null, 'shared']);
      expect(category.sourceItemIds, ['shared', 'missing', 'shared']);
      expect(
        category.resolutionIssues.single.source.path,
        'aisles[0].sub[$index].categories[0].itemIds[1]',
      );
      expect(category.resolutionIssues.single.source.shopId, 'a');
      expect(category.extras['future'], {
        'keep': [null, 1],
      });
    }
    expect(
      identical(
        detail.sub.first.categories.first.itemIds.first,
        detail.sub.last.categories.first.itemIds.first,
      ),
      isTrue,
    );
    expect(() => detail.sub.clear(), throwsUnsupportedError);
    expect(() => detail.sub.first.categories.clear(), throwsUnsupportedError);
    expect(
      () => detail.sub.first.categories.first.itemIds.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => (detail.extras['extra']! as List).clear(),
      throwsUnsupportedError,
    );
    final json = detail.toSourceJson();
    (json['sub']! as List).clear();
    expect(detail.sub, hasLength(2));
    expect((detail.toJson()['sub']! as List).first, isA<Map>());
  });

  test(
    'empty hierarchy, absent associations, unknown and ambiguous aisle policy',
    () async {
      final assets = data();
      final raw = aisle();
      assets[MockConfig.hierarchyAsset] = fixture.lines([
        {
          'shopID': 'a',
          'aisles': [raw, raw],
        },
        {'shopID': 'b', 'aisles': []},
      ]);
      final diagnostics = <ResolutionIssue>[];
      final repository = repo(assets, sink: diagnostics.add);
      final detail = MockAisleDetailService(repository: repository);
      final summaries = MockShopByAisleService(repository: repository);
      expect(await detail.getAisleDetail('a', 'aisle'), isNull);
      expect(diagnostics.last.code, 'ambiguous_aisle');
      expect(await detail.getAisleDetail('a', 'missing'), isNull);
      expect(await summaries.getAisles('b'), isEmpty);
      expect(await detail.getAisleDetail('b', 'aisle'), isNull);
      expect(await summaries.getAisles('unknown'), isNull);
      await expectLater(detail.getAisleDetail('a', ''), throwsArgumentError);
      final noHierarchy = repo(data()..[MockConfig.hierarchyAsset] = '');
      expect(
        await MockShopByAisleService(repository: noHierarchy).getAisles('a'),
        isNull,
      );
    },
  );

  test(
    'missing versus empty product files retain memberships and distinct issues',
    () async {
      for (final absent in [true, false]) {
        final assets = data();
        if (absent) {
          assets.remove(catalog('a'));
        } else {
          assets[catalog('a')] = '';
        }
        final diagnostics = <ResolutionIssue>[];
        final repository = repo(assets, sink: diagnostics.add);
        final detail = (await MockAisleDetailService(repository: repository)
            .getAisleDetail('a', 'aisle'))!;
        final category = detail.sub.first.categories.first;
        expect(category.itemIds, [null, null, null]);
        expect(category.resolutionIssues.map((i) => i.code).toSet(), {
          absent ? 'missing_product_file' : 'missing_product_id',
        });
        expect(
          await MockProductService(repository: repository)
              .getProduct('a', 'shared'),
          isNull,
        );
        final displays = await MockStoreFilterByService(repository: repository)
            .getStoresDisplay();
        if (absent) {
          expect(displays, isNull);
        } else {
          expect(
            displays
                ?.where((d) => d.store.id == 'a')
                .every((d) => d.proudcts.isEmpty),
            isTrue,
          );
        }
      }
    },
  );

  test(
    'identical and conflicting rows share one resolver across all consumers',
    () async {
      final assets = data();
      final same = fixture.product('shared');
      assets[catalog('a')] = fixture.lines([
        same,
        same,
        fixture.product('ambiguous'),
        fixture.product('ambiguous')..['price'] = 'changed',
        fixture.product('other'),
      ]);
      assets[MockConfig.categoryAsset] = fixture.lines([
        fixture.membership(
          'a',
          entries: [
            {
              'categoryId': 1,
              'title': 'Title',
              'items': ['shared', 'ambiguous', 'missing', 'shared'],
            },
          ],
        ),
      ]);
      final diagnostics = <ResolutionIssue>[];
      final repository = repo(assets, sink: diagnostics.add);
      final ProductService service = MockProductService(repository: repository);
      final shared = await service.getProduct('a', 'shared');
      expect(shared?.sources.map((s) => s.line), [1, 2]);
      expect(diagnostics.last.code, 'duplicate_identical_product');
      expect(await service.getProduct('a', 'ambiguous'), isNull);
      expect(diagnostics.last.code, 'conflicting_product_records');
      expect(diagnostics.last.matches.map((s) => s.line), [3, 4]);
      final category = (await MockStorePage(
        repository: repository,
      ).getCategories('a'))!.single;
      expect(category.items.map((p) => p?.id), [
        'shared',
        null,
        null,
        'shared',
      ]);
      expect(identical(shared, category.items.first), isTrue);
      expect(category.resolutionIssues.map((i) => i.code), [
        'duplicate_identical_product',
        'conflicting_product_records',
        'missing_product_id',
        'duplicate_identical_product',
      ]);
      final recommendations = (await service.getProductDisplay('a', 'shared'))!;
      expect(
        recommendations.every((g) => g.proudcts.single.id == 'other'),
        isTrue,
      );
      await expectLater(
        repository.productsForStore('a'),
        throwsA(isA<MockDataException>()),
      );
    },
  );

  test('recommendations use distinct labels, exclude anchor and never pad tiny pools', () async {
    for (final count in [1, 2, 9]) {
      final assets = data()
        ..[catalog('a')] = fixture.lines(
          List.generate(count, (i) => fixture.product('$i')),
        );
      final service = MockProductService(repository: repo(assets));
      for (var i = 0; i < 10; i++) {
        final groups = (await service.getProductDisplay('a', '0'))!;
        if (count == 1) {
          expect(groups, isEmpty);
          continue;
        }
        expect(groups.length, inInclusiveRange(1, 5));
        expect(groups.map((g) => g.f_label).toSet(), hasLength(groups.length));
        for (final group in groups) {
          expect(group.proudcts, hasLength(count - 1 < 5 ? count - 1 : 5));
          expect(
            group.proudcts.map((p) => p.id).toSet(),
            hasLength(group.proudcts.length),
          );
          expect(
            group.proudcts.every((p) => p.shopId == 'a' && p.id != '0'),
            isTrue,
          );
          expect(() => group.proudcts.clear(), throwsUnsupportedError);
        }
        expect(() => groups.clear(), throwsUnsupportedError);
      }
    }
  });

  test(
    'identity-based enrichment survives reversed loading and source row order',
    () async {
      final assets = data();
      final reversed = data();
      reversed[catalog('a')] = fixture.lines([
        fixture.product('second-a'),
        fixture.product('shared', variants: [], unit: {'value': 'source'}),
      ]);
      final first = repo(assets);
      final second = repo(reversed);
      final a = MockProductService(repository: first);
      final b = MockProductService(repository: second);
      await b.getProduct('b', 'shared');
      await MockAisleDetailService(repository: second)
          .getAisleDetail('a', 'aisle');
      expect(
        (await a.getProduct('a', 'shared'))?.toJson(),
        (await b.getProduct('a', 'shared'))?.toJson(),
      );
      final aStores = (await first.stores())!;
      final bStores = (await second.stores())!;
      expect(aStores.map((s) => s.toJson()), bStores.map((s) => s.toJson()));
      final purchaseValues = <int?>{};
      final stockValues = <bool>{};
      final foodValues = <String?>{};
      for (var seed = 0; seed < 50; seed++) {
        final p = (await MockProductService(
          repository: repo(assets, seed: seed),
        ).getProduct('a', 'shared'))!;
        purchaseValues.add(p.f_purchaseHistory);
        stockValues.add(p.f_isManyInStock);
        foodValues.add(p.f_freeText);
        if (p.f_purchaseHistory != null) {
          expect(p.f_purchaseHistory, inInclusiveRange(100, 500));
        }
        if (p.f_freeText != null) {
          expect(MockConfig.foodLabels, contains(p.f_freeText));
        }
        expect(
          p.toSourceJson(),
          fixture.product('shared', variants: [], unit: {'value': 'source'}),
        );
      }
      expect(purchaseValues, contains(null));
      expect(purchaseValues.whereType<int>(), isNotEmpty);
      expect(stockValues, {true, false});
      expect(foodValues, contains(null));
      expect(foodValues.whereType<String>(), isNotEmpty);
    },
  );

  test(
    'concurrent calls share independent sources and catalog indices',
    () async {
      final source = fixture.CountingTextSource(data());
      final repository = MockDataRepository(seed: 42, textDataSource: source);
      final products = MockProductService(repository: repository);
      final aisles = MockShopByAisleService(repository: repository);
      final detail = MockAisleDetailService(repository: repository);
      await Future.wait<Object?>([
        products.getProduct('a', 'shared'),
        products.getProductDisplay('a', 'shared'),
        aisles.getAisles('a'),
        detail.getAisleDetail('a', 'aisle'),
        MockStorePage(repository: repository).getCategories('a'),
      ]);
      expect(source.loads.values, everyElement(1));
      expect(source.loads.containsKey(catalog('b')), isFalse);
      expect(source.loads.containsKey(MockConfig.carouselAsset), isFalse);
      final first = await detail.getAisleDetail('a', 'aisle');
      final second = await detail.getAisleDetail('a', 'aisle');
      expect(
        identical(first, second),
        isFalse,
      ); // expanded responses aren't cached
      expect(
        identical(
          first?.sub.first.categories.first.itemIds.first,
          second?.sub.first.categories.first.itemIds.first,
        ),
        isTrue,
      );
    },
  );

  test(
    'corruption and conflicting association records throw with source context',
    () async {
      for (final raw in [
        {'shopID': 'a', 'shopId': 'b', 'aisles': []},
        {'shopID': 'a', 'aisles': 'wrong'},
        {
          'shopID': 'a',
          'aisles': [aisle()..['imageUrl'] = 42],
        },
      ]) {
        final assets = data()
          ..[MockConfig.hierarchyAsset] = fixture.lines([raw]);
        await expectLater(
          MockShopByAisleService(repository: repo(assets)).getAisles('a'),
          throwsA(
            isA<MockDataException>().having(
              (e) => e.sourceName,
              'asset',
              MockConfig.hierarchyAsset,
            ),
          ),
        );
      }
      final assets = data()
        ..[MockConfig.hierarchyAsset] = fixture.lines([
          {
            'shopID': 'a',
            'aisles': [aisle()],
          },
          {'shopID': 'a', 'aisles': []},
        ]);
      await expectLater(
        MockShopByAisleService(repository: repo(assets)).getAisles('a'),
        throwsA(isA<MockDataException>()),
      );
      assets[MockConfig.hierarchyAsset] = fixture.lines([
        {
          'shopID': 'a',
          'aisles': [aisle()..['sub'] = false],
        },
      ]);
      await expectLater(
        MockAisleDetailService(repository: repo(assets))
            .getAisleDetail('a', 'aisle'),
        throwsA(isA<MockDataException>()),
      );
    },
  );

  test(
    'known unavailable roots return null while inventoried I/O errors throw',
    () async {
      final repository = repo({});
      expect(
        await MockDashboardService(repository: repository).getStoreDisplays(),
        isNull,
      );
      expect(
        await MockStoreFilterByService(repository: repository)
            .getCarouselsAtHeader(),
        isNull,
      );
      final failed = MockDataRepository(
        textDataSource: InMemoryMockTextDataSource({}),
        assetInventory: {MockConfig.storeAsset},
      );
      await expectLater(
        MockDashboardService(repository: failed).getAllStores(),
        throwsA(isA<MockDataException>()),
      );
    },
  );
}
