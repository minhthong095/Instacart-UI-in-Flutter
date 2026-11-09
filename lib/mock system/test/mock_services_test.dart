import 'dart:convert';

// Tests live with the requested mock service output, using its dev dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../mock_system.dart';

Map<String, Object?> store(String id) => {
  'shopId': id,
  'background_color': '#123aBc',
  'name': 'Shop $id',
  'retailer_id': 'different-retailer',
  'image': ['b', 'a'],
  'tags': ['real'],
};

Map<String, Object?> product(String id, {Object? variants, Object? unit}) => {
  'id': id,
  'variants': variants,
  'images': [
    {
      'url': 'image',
      'templateUrl': '{width=}',
      'future': [1, null],
    },
  ],
  'sections': [
    {'headerString': 'Details', 'bodyString': 'Raw\ntext', 'more': true},
  ],
  'name': 'Source name',
  'isNutritionAvailable': true,
  'proudctSlug': '/raw-slug',
  'pricePerUnit': unit,
  'fullPrice': r'$3.00',
  'pricingUnit': null,
  'price': r'$2.00',
  'isLoyaltyProgramAvailbale': false,
  'offerLabelString': null,
  'future': {
    'nested': [
      null,
      true,
      {'key': 'value'},
    ],
  },
};

Map<String, Object?> carousel(String id) => {
  'id': id,
  'name': 'Source $id',
  'image': 'https://image/{width=}/{height=}',
  'slug': '/raw-$id',
  'future': {
    'array': [1, 2],
  },
};

Map<String, Object?> membership(String id, {List<Object?>? entries}) => {
  'shopId': id,
  'productCategory':
      entries ??
      [
        {
          'categoryId': 287,
          'title': 'Exact title',
          'items': ['same', 'same', 'other'],
          'future': {
            'keep': [null, 1],
          },
        },
        {
          'categoryId': 287,
          'title': 'Repeated category occurrence',
          'items': [],
        },
      ],
};

String lines(Iterable<Object?> rows) => rows.map(jsonEncode).join('\n');

String productAsset(String id) =>
    '${MockConfig.productAssetDirectory}/$id.jsonl';

Map<String, String> fixtures({List<String> ids = const ['a', 'b']}) => {
  MockConfig.storeAsset: lines(ids.map(store)),
  MockConfig.carouselAsset: lines([
    for (final id in ids)
      {
        'shopId': id,
        'carousel': [carousel('first'), carousel('second')],
      },
  ]),
  MockConfig.categoryAsset: lines(ids.map(membership)),
  for (final id in ids)
    productAsset(id): lines([
      product('shared', variants: [], unit: {'value': 'source'}),
      product('second-$id'),
    ]),
};

MockDataRepository repository(Map<String, String> data, {int seed = 42}) =>
    MockDataRepository(
      seed: seed,
      textDataSource: InMemoryMockTextDataSource(data),
    );

TypeMatcher<MockDataException> contextualError(
  String asset, {
  String? containsMessage,
}) => isA<MockDataException>()
    .having((e) => e.sourceName, 'asset', asset)
    .having((e) => e.message, 'message', contains(containsMessage ?? ''));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('100 short unique goods labels and seven central dashboard labels', () {
    expect(MockConfig.serviceLabels, hasLength(100));
    expect(MockConfig.serviceLabels.toSet(), hasLength(100));
    expect(
      MockConfig.serviceLabels.every(
        (s) => s.trim().isNotEmpty && s.length <= 5,
      ),
      isTrue,
    );
    expect(MockConfig.displayLabels, hasLength(7));
  });

  test(
    'cold page initialization does not advance carousel selection randomness',
    () async {
      final data = fixtures(ids: List.generate(20, (i) => '$i'));
      final withPage = repository(data);
      final withoutPage = repository(data);
      (await MockStorePage(repository: withPage).getCategories('0'))!;
      final first = (await MockStoreFilterByService(repository: withPage)
          .getCarouselsAtHeader())!;
      final second = (await MockStoreFilterByService(repository: withoutPage)
          .getCarouselsAtHeader())!;
      expect(
        first.map((c) => [c.shopId, c.id]),
        second.map((c) => [c.shopId, c.id]),
      );
    },
  );

  for (final count in [1, 4, 5, 19, 20, 99, 100, 108]) {
    test(
      'all counts and identity-preserving fallback with $count stores',
      () async {
        final ids = List.generate(count, (i) => '$i');
        final repo = repository(fixtures(ids: ids));
        final DashboardService dashboard = MockDashboardService(
          repository: repo,
        );
        final StoreFilterByService filter = MockStoreFilterByService(
          repository: repo,
        );
        final header = (await dashboard.getStoreDisplayOnHeader())!;
        final groups = (await dashboard.getStoreDisplays())!;
        final allDashboard = (await dashboard.getAllStores())!;
        final allFilter = (await filter.getAllStores())!;
        final displays = (await filter.getStoresDisplay())!;
        final carousels = (await filter.getCarouselsAtHeader())!;
        void sampleCheck(List<Store> result, int required) {
          expect(result, hasLength(required));
          expect(
            result
                .take(count < required ? count : required)
                .map((s) => s.id)
                .toSet(),
            hasLength(count < required ? count : required),
          );
        }

        sampleCheck(header, 20);
        expect(groups, hasLength(7));
        for (final group in groups) {
          sampleCheck(group.store, 5);
        }
        sampleCheck(allDashboard, 100);
        sampleCheck(allFilter, 100);
        sampleCheck(displays.map((d) => d.store).toList(), 5);
        expect(carousels, hasLength(11));
        final poolSize = count * 2;
        expect(
          carousels
              .take(poolSize < 11 ? poolSize : 11)
              .map((c) => '${c.shopId}/${c.id}')
              .toSet(),
          hasLength(poolSize < 11 ? poolSize : 11),
        );
        final canonical = {for (final s in (await repo.stores())!) s.id: s};
        for (final s in [
          ...header,
          ...allDashboard,
          ...allFilter,
          ...groups.expand((g) => g.store),
          ...displays.map((d) => d.store),
        ]) {
          expect(identical(s, canonical[s.id]), isTrue);
          expect(s.backgroundColor, '#123aBc');
        }
        for (final display in displays) {
          expect(MockConfig.serviceLabels, contains(display.f_label));
          expect(display.proudcts.map((p) => p.id), [
            'shared',
            'second-${display.store.id}',
          ]);
          expect(
            display.proudcts.every((p) => p.shopId == display.store.id),
            isTrue,
          );
        }
      },
    );
  }

  test('both store pages are scoped, ordered, unpadded, and preserve exact payloads', () async {
    final data = fixtures();
    final repo = repository(data);
    final StorePage page = MockStorePage(repository: repo);
    final first = (await page.getCarousels(' a '))!;
    expect(first.map((c) => c.id), ['first', 'second']);
    expect(first.every((c) => c.shopId == 'a'), isTrue);
    expect(first.first.toJson(), carousel('first'));
    expect(first.first.image, contains('{width=}/{height=}'));
    final categories = (await page.getCategories(' a '))!;
    expect(categories, hasLength(2));
    expect(categories.map((c) => c.categoryId), [287, 287]);
    expect(categories.first.title, 'Exact title');
    expect(categories.first.sourceItemIds, ['same', 'same', 'other']);
    expect(categories.last.items, isEmpty);
    expect(
      categories.first.toSourceJson(),
      (membership('a')['productCategory']! as List).first,
    );
    expect(categories.first.source.asset, MockConfig.categoryAsset);
    expect(categories.first.source.path, 'productCategory[0]');
    final sampled = (await MockStoreFilterByService(repository: repo)
        .getCarouselsAtHeader())!;
    expect(
      sampled
          .where((c) => c.shopId == 'a' && c.id == 'first')
          .every((c) => identical(c, first.first)),
      isTrue,
    );
  });

  test(
    'absent associations and unknown IDs are null; invalid IDs reject',
    () async {
      final data = fixtures(ids: ['a', 'b', 'c']);
      data[MockConfig.carouselAsset] = lines([
        {'shopId': 'a', 'carousel': []},
      ]);
      data[MockConfig.categoryAsset] = lines([membership('a', entries: [])]);
      final StorePage page = MockStorePage(repository: repository(data));
      expect(await page.getCarousels('a'), isEmpty);
      expect(await page.getCategories('a'), isEmpty);
      for (final id in ['b', 'c', 'unknown', 'different-retailer']) {
        expect(await page.getCarousels(id), isNull);
        expect(await page.getCategories(id), isNull);
      }
      for (final id in ['', '   ', '../outside', 'a/b']) {
        await expectLater(page.getCarousels(id), throwsArgumentError);
        await expectLater(page.getCategories(id), throwsArgumentError);
      }
    },
  );

  test('missing products preserve category parents independently of carousel assets', () async {
    final data = fixtures()..remove(MockConfig.carouselAsset);
    data.removeWhere(
      (key, _) => key.startsWith(MockConfig.productAssetDirectory),
    );
    final source = CountingTextSource(data);
    final repo = MockDataRepository(seed: 42, textDataSource: source);
    final StorePage page = MockStorePage(repository: repo);
    expect((await page.getCategories('a'))!, hasLength(2));
    expect(source.loads.keys.toSet(), {
      MockConfig.storeAsset,
      MockConfig.categoryAsset,
    });
    final DashboardService dashboard = MockDashboardService(repository: repo);
    expect((await dashboard.getAllStores())!, hasLength(100));
    expect(source.loads.keys.toSet(), {
      MockConfig.storeAsset,
      MockConfig.categoryAsset,
    });
    expect(await page.getCarousels('a'), isNull);
  });

  test('missing product file fails selected shop; valid empty file returns no products', () async {
    final data = fixtures(ids: ['a'])..remove(productAsset('a'));
    final filter = MockStoreFilterByService(repository: repository(data));
    expect(await filter.getStoresDisplay(), isNull);
    data[productAsset('a')] = '\n \n';
    final displays = (await MockStoreFilterByService(
      repository: repository(data),
    ).getStoresDisplay())!;
    expect(displays, hasLength(5));
    expect(
      displays.every((d) => d.proudcts.isEmpty && d.store.id == 'a'),
      isTrue,
    );
  });

  test('products retain source values, nested extras, unknown JSON and shop-scoped IDs', () async {
    final data = fixtures();
    final repo = repository(data);
    final a = (await repo.productsForStore('a'))!;
    final b = (await repo.productsForStore('b'))!;
    expect(a.first.id, b.first.id);
    expect(identical(a.first, b.first), isFalse);
    expect(a.first.shopId, 'a');
    expect(b.first.shopId, 'b');
    expect(a.first.variants, isEmpty);
    expect(a.first.pricePerUnit, {'value': 'source'});
    expect(a.first.pricingUnit, isNull);
    expect(
      a.first.toSourceJson(),
      product('shared', variants: [], unit: {'value': 'source'}),
    );
    expect(
      a.first.images.first.toJson(),
      (product('x')['images']! as List).first,
    );
    expect(a.first.sections.first.bodyString, 'Raw\ntext');
    expect(a.last.variants, isNull);
    expect(a.last.pricePerUnit, isNull);
    expect(a.first.source.shopId, 'a');
    expect(a.first.source.line, 1);
  });

  test(
    'returned lists, JSON collections and extras cannot mutate cached data',
    () async {
      final repo = repository(fixtures());
      final filter = MockStoreFilterByService(repository: repo);
      final page = MockStorePage(repository: repo);
      final displays = (await filter.getStoresDisplay())!;
      final carousels = (await filter.getCarouselsAtHeader())!;
      final categories = (await page.getCategories('a'))!;
      final p = displays.first.proudcts.first;
      expect(() => displays.clear(), throwsUnsupportedError);
      expect(() => displays.first.proudcts.clear(), throwsUnsupportedError);
      expect(() => p.images.clear(), throwsUnsupportedError);
      expect(() => p.sections.clear(), throwsUnsupportedError);
      expect(() => p.variants!.clear(), throwsUnsupportedError);
      expect(() => (p.pricePerUnit! as Map).clear(), throwsUnsupportedError);
      expect(
        () => ((p.extras['future']! as Map)['nested']! as List).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => (p.images.first.extras['future']! as List).clear(),
        throwsUnsupportedError,
      );
      expect(() => categories.clear(), throwsUnsupportedError);
      expect(() => categories.first.items.clear(), throwsUnsupportedError);
      expect(() => carousels.clear(), throwsUnsupportedError);
      expect(
        () => (carousels.first.extras['future']! as Map).clear(),
        throwsUnsupportedError,
      );
      final detached = p.toJson();
      (detached['images']! as List).clear();
      expect(p.images, hasLength(1));
      (categories.first.toJson()['items']! as List).clear();
      expect(categories.first.items, hasLength(3));
    },
  );

  test('same seed and mixed sequential call sequence repeats; pages consume no randomness', () async {
    final data = fixtures(ids: List.generate(25, (i) => '$i'));
    Future<List<Object?>> sequence(
      MockDataRepository repo, {
      bool pages = false,
    }) async {
      final d = MockDashboardService(repository: repo);
      final f = MockStoreFilterByService(repository: repo);
      final p = MockStorePage(repository: repo);
      final result = <Object?>[];
      for (var i = 0; i < 2; i++) {
        result.add(
          ((await d.getStoreDisplayOnHeader())!)
              .map((s) => s.toJson())
              .toList(),
        );
        result.add(
          ((await d.getStoreDisplays())!).map((g) => g.toJson()).toList(),
        );
        if (pages) {
          (await p.getCategories('0'))!;
          (await p.getCarousels('0'))!;
        }
        result.add(((await d.getAllStores())!).map((s) => s.toJson()).toList());
        result.add(
          ((await f.getCarouselsAtHeader())!)
              .map((c) => [c.shopId, c.toJson()])
              .toList(),
        );
        result.add(
          ((await f.getStoresDisplay())!).map((g) => g.toJson()).toList(),
        );
        result.add(((await f.getAllStores())!).map((s) => s.toJson()).toList());
      }
      return result;
    }

    expect(
      await sequence(repository(data)),
      await sequence(repository(data), pages: true),
    );
    // Prove subsequent calls consume selection randomness without asserting that
    // any particular random pair must be different (overlap is permitted).
    final repo = repository(data);
    final d = MockDashboardService(repository: repo);
    final first = (await d.getAllStores())!;
    (await d.getAllStores())!;
    expect(first, hasLength(100));
    expect(
      first.first,
      same(((await repo.stores())!).firstWhere((s) => s.id == first.first.id)),
    );
  });

  test('concurrent and subsequent calls share all initialization and per-shop futures', () async {
    final source = CountingTextSource(fixtures());
    final repo = MockDataRepository(seed: 42, textDataSource: source);
    final d = MockDashboardService(repository: repo);
    final f = MockStoreFilterByService(repository: repo);
    final p = MockStorePage(repository: repo);
    await Future.wait<Object?>([
      d.getStoreDisplayOnHeader(),
      d.getStoreDisplays(),
      d.getAllStores(),
      f.getAllStores(),
      f.getCarouselsAtHeader(),
      f.getStoresDisplay(),
      p.getCarousels('a'),
      p.getCategories('a'),
      p.getCategories('b'),
      repo.productsForStore('a'),
      repo.productsForStore('a'),
    ]);
    (await f.getStoresDisplay())!;
    (await p.getCarousels('a'))!;
    (await p.getCategories('a'))!;
    expect(source.loads.values, everyElement(1));
    expect(source.loads.keys.toSet(), fixtures().keys.toSet());
  });

  test('identical duplicates collapse; category occurrences and item repetitions remain', () async {
    final data = fixtures(ids: ['a']);
    final c = carousel('first');
    final p = product('shared');
    data[MockConfig.carouselAsset] = lines([
      {
        'shopId': 'a',
        'carousel': [c, c, carousel('second')],
      },
      {
        'shopId': 'a',
        'carousel': [c],
      },
    ]);
    data[productAsset('a')] = lines([
      p,
      Map.fromEntries(p.entries.toList().reversed),
      product('last'),
    ]);
    data[MockConfig.categoryAsset] = lines([membership('a'), membership('a')]);
    final repo = repository(data);
    expect(((await repo.carouselsForStore('a'))!).map((c) => c.id), [
      'first',
      'second',
    ]);
    expect(((await repo.productsForStore('a'))!).map((p) => p.id), [
      'shared',
      'last',
    ]);
    final categories = (await repo.categoriesForStore('a'))!;
    expect(categories, hasLength(2));
    expect(categories.first.sourceItemIds, ['same', 'same', 'other']);
  });

  test(
    'conflicting duplicates fail with file, line, shop and entry context',
    () async {
      final data = fixtures(ids: ['a']);
      data[MockConfig.carouselAsset] = lines([
        {
          'shopId': 'a',
          'carousel': [carousel('x'), carousel('x')..['name'] = 'conflict'],
        },
      ]);
      data[productAsset('a')] = lines([
        product('x'),
        product('x')..['price'] = 'conflict',
      ]);
      data[MockConfig.categoryAsset] = lines([
        membership('a'),
        membership('a', entries: []),
      ]);
      final repo = repository(data);
      for (final future in [
        repo.carouselsForStore('a'),
        repo.productsForStore('a'),
        repo.categoriesForStore('a'),
      ]) {
        await expectLater(
          future,
          throwsA(
            isA<MockDataException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Shop a: Conflicting duplicate'),
                )
                .having(
                  (e) => e.message,
                  'first source',
                  contains('first occurrence'),
                )
                .having((e) => e.lineNumber, 'line', isNotNull),
          ),
        );
      }
    },
  );

  test(
    'malformed, missing and incompatible datasets fail their affected method',
    () async {
      for (final asset in [
        MockConfig.carouselAsset,
        MockConfig.categoryAsset,
        productAsset('a'),
      ]) {
        for (final bad in ['not-json', '[]']) {
          final data = fixtures(ids: ['a'])..[asset] = '\n$bad';
          final repo = repository(data);
          final future = asset == MockConfig.carouselAsset
              ? repo.carouselsForStore('a')
              : asset == MockConfig.categoryAsset
              ? repo.categoriesForStore('a')
              : repo.productsForStore('a');
          await expectLater(
            future,
            throwsA(
              contextualError(asset).having((e) => e.lineNumber, 'line', 2),
            ),
          );
        }
      }
      for (final entry in [
        {'categoryId': '287', 'title': 'Wrong ID', 'items': []},
        {'categoryId': 287, 'title': null, 'items': []},
        {
          'categoryId': 287,
          'title': 'Wrong items',
          'items': [1],
        },
      ]) {
        final data = fixtures()
          ..[MockConfig.categoryAsset] = lines([
            membership('a', entries: [entry]),
          ]);
        await expectLater(
          repository(data).categoriesForStore('a'),
          throwsA(contextualError(MockConfig.categoryAsset)),
        );
      }
      final navigationData = fixtures()
        ..[MockConfig.categoryAsset] = lines([
          {
            'shopId': 'a',
            'categories': [
              {
                'title': 'Navigation only',
                'productCategoryIds': [287],
              },
            ],
          },
        ]);
      await expectLater(
        repository(navigationData).categoriesForStore('a'),
        throwsA(contextualError(MockConfig.categoryAsset)),
      );
      final missing = fixtures()..remove(MockConfig.categoryAsset);
      expect(await repository(missing).categoriesForStore('a'), isNull);
    },
  );

  test(
    'empty carousel root pool is empty and absent shop association is null',
    () async {
      final data = fixtures()..[MockConfig.carouselAsset] = '\n';
      final repo = repository(data);
      expect(await repo.carouselsForStore('a'), isNull);
      expect(
        await MockStoreFilterByService(repository: repo).getCarouselsAtHeader(),
        isEmpty,
      );
    },
  );

  test('failed product initialization is cached per shop while other shops still load', () async {
    final data = fixtures()..remove(productAsset('a'));
    final source = CountingTextSource(data);
    final repo = MockDataRepository(
      textDataSource: source,
      assetInventory: {...data.keys, productAsset('a')},
    );
    await Future.wait([
      expectLater(
        repo.productsForStore('a'),
        throwsA(isA<MockDataException>()),
      ),
      expectLater(
        repo.productsForStore('a'),
        throwsA(isA<MockDataException>()),
      ),
    ]);
    await expectLater(
      repo.productsForStore('a'),
      throwsA(isA<MockDataException>()),
    );
    expect((await repo.productsForStore('b'))!, hasLength(2));
    expect(source.loads[productAsset('a')], 1);
    expect(source.loads[productAsset('b')], 1);
  });

  test('service latency does not change seed results; invalid configuration rejects', () async {
    final data = fixtures();
    final delayed = MockStorePage(
      repository: repository(data),
      latency: const Duration(milliseconds: 10),
    );
    final clock = Stopwatch()..start();
    expect((await delayed.getCategories('a'))!, hasLength(2));
    expect(
      clock.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 10)),
    );
    expect(
      () => MockStoreFilterByService(latency: const Duration(milliseconds: -1)),
      throwsArgumentError,
    );
    expect(
      () => MockStorePage(latency: const Duration(milliseconds: -1)),
      throwsArgumentError,
    );
    expect(
      () => MockDashboardService(repository: repository(data), seed: 1),
      throwsArgumentError,
    );
  });
}

class CountingTextSource implements MockTextDataSource, MockAssetInventory {
  CountingTextSource(this.assets);
  final Map<String, String> assets;
  @override
  Set<String> get availableAssets => Set.unmodifiable(assets.keys);
  final loads = <String, int>{};

  @override
  Future<String> loadText(String asset) async {
    loads.update(asset, (n) => n + 1, ifAbsent: () => 1);
    await Future<void>.delayed(Duration.zero);
    if (!assets.containsKey(asset)) throw StateError('Missing fixture');
    return assets[asset]!;
  }
}
