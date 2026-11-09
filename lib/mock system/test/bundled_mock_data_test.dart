import 'dart:convert';

import 'package:flutter/services.dart';
// Tests live under the requested output directory; flutter_test is a dev dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import '../mock_system.dart';

List<Map<String, dynamic>> decodeLines(String text) => const LineSplitter()
    .convert(text)
    .where((line) => line.trim().isNotEmpty)
    .map((line) => jsonDecode(line) as Map<String, dynamic>)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'full bundled carousel and category source lists match every known store',
    () async {
      final sourceCarousels = decodeLines(
        await rootBundle.loadString(MockConfig.carouselAsset),
      );
      final sourceCategories = decodeLines(
        await rootBundle.loadString(MockConfig.categoryAsset),
      );
      final carouselByShop = {
        for (final r in sourceCarousels) r['shopId']: r['carousel'],
      };
      final categoryByShop = {
        for (final r in sourceCategories) r['shopId']: r['productCategory'],
      };
      final repo = MockDataRepository(seed: 42);
      final StorePage page = MockStorePage(repository: repo);
      for (final store in (await repo.stores())!) {
        final carousels = (await page.getCarousels(store.id))!;

        expect(
          carousels.map((c) => c.toJson()).toList(),
          carouselByShop[store.id] ?? [],
        );

        expect(carousels.every((c) => c.shopId == store.id), isTrue);
      }
      expect((await page.getCarousels('1175'))!, hasLength(13));
      final categories = (await page.getCategories('1175'))!;
      expect(categories, hasLength(38));
      expect(
        categories.map((c) => c.toSourceJson()).toList(),
        categoryByShop['1175'],
      );
      expect(
        categories.expand((c) => c.items).where((p) => p == null),
        isNotEmpty,
      );
      expect(await page.getCategories('15114'), isNull);
      expect((await page.getCarousels('2202'))!, isEmpty);
    },
  );

  test(
    'full bundled product mapping is lossless and ownership uses filename',
    () async {
      // One file includes nonempty variant IDs, multiple images and nullable units;
      // the smaller file is the guide's original sample. No ID prefix joins occur.
      for (final id in ['596896', '16655224']) {
        final asset = '${MockConfig.productAssetDirectory}/$id.jsonl';
        final raw = decodeLines(await rootBundle.loadString(asset));
        final expected = <String, Map<String, dynamic>>{};
        for (final row in raw) {
          expected.putIfAbsent(row['id'] as String, () => row);
        }
        final products = (await MockDataRepository(seed: 42)
            .productsForStore(id))!;
        expect(
          products.map((p) => p.toSourceJson()).toList(),
          expected.values.toList(),
        );
        expect(
          products.every((p) => p.shopId == id && p.source.asset == asset),
          isTrue,
        );
        for (final p in products) {
          expect(p.variants, expected[p.id]!['variants']);
          expect(p.pricingUnit, expected[p.id]!['pricingUnit']);
        }
      }
    },
  );

  test(
    'active hierarchy maps images and lossless selected-aisle hydration',
    () async {
      final text = await rootBundle.loadString(MockConfig.hierarchyAsset);
      final raw = LineSplitter.split(text)
          .where((line) => line.trim().isNotEmpty)
          .map((line) => jsonDecode(line) as Map<String, dynamic>)
          .firstWhere((row) => row['shopID'] == '1175');
      final rawAisles = raw['aisles'] as List;
      final repository = MockDataRepository(seed: 42);
      final summaries = (await MockShopByAisleService(repository: repository)
          .getAisles('1175'))!;
      expect(summaries, hasLength(rawAisles.length));
      for (var i = 0; i < summaries.length; i++) {
        expect(summaries[i].imageUrl, rawAisles[i]['imageUrl']);
      }
      final selected =
          rawAisles.firstWhere((a) => a['id'] == '88') as Map<String, dynamic>;
      final detail = (await MockAisleDetailService(repository: repository)
          .getAisleDetail('1175', selected['id'] as String))!;
      expect(detail.toSourceJson(), selected);
      final categories = detail.sub.expand((sub) => sub.categories).toList();
      expect(
        categories.expand((c) => c.itemIds).whereType<Proudct>(),
        isNotEmpty,
      );
      expect(
        categories.expand((c) => c.itemIds).where((p) => p == null),
        isNotEmpty,
      );
      for (final category in categories) {
        expect(category.itemIds.length, category.sourceItemIds.length);
        for (var i = 0; i < category.itemIds.length; i++) {
          final product = category.itemIds[i];
          if (product != null) {
            expect(product.shopId, '1175');
            expect(product.id, category.sourceItemIds[i]);
          }
        }
      }
    },
  );

  for (final entry in {'3027': 2429, '95087': 746}.entries) {
    test(
      'bundled source conflict in shop ${entry.key} is explicit and does not affect pages',
      () async {
        final repo = MockDataRepository(seed: 42);
        await expectLater(
          repo.productsForStore(entry.key),
          throwsA(
            isA<MockDataException>()
                .having(
                  (e) => e.sourceName,
                  'source',
                  '${MockConfig.productAssetDirectory}/${entry.key}.jsonl',
                )
                .having((e) => e.lineNumber, 'conflict line', entry.value)
                .having((e) => e.message, 'shop', contains('Shop ${entry.key}'))
                .having(
                  (e) => e.message,
                  'conflict',
                  contains('Conflicting duplicate product'),
                ),
          ),
        );
        expect((await repo.categoriesForStore(entry.key))!, isNotEmpty);
        expect((await repo.carouselsForStore(entry.key))!, isNotEmpty);
      },
    );
  }
}
