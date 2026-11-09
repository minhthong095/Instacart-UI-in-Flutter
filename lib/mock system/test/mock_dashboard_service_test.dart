import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
// Tests stay under the requested output directory; flutter_test is a dev dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

import 'package:tangerine/mock%20system/mock_system.dart';

Map<String, Object?> record(Object id) => {
  'shopId': id,
  'background_color': '#aBc123',
  'name': 'Store $id',
  'slug': 'store-$id',
  'retailer_id': 'retailer-9',
  'image': ['second-size.png', 'first-size.png'],
  'tags': ['Real source tag'],
};

String jsonl(Iterable<Map<String, Object?>> records) =>
    records.map(jsonEncode).join('\n');

MockDashboardService serviceFor(String text, {int seed = 42}) =>
    MockDashboardService(
      seed: seed,
      dataSource: InMemoryStoreDataSource(text, sourceName: 'fixture.jsonl'),
    );

Matcher dataError({int? line, String? field, String? message}) =>
    isA<MockDataException>()
        .having((error) => error.sourceName, 'source', 'fixture.jsonl')
        .having((error) => error.lineNumber, 'line', line)
        .having((error) => error.field, 'field', field)
        .having((error) => error.message, 'message', contains(message ?? ''));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'returns exact counts and distinct IDs when enough stores exist',
    () async {
      final DashboardService service = serviceFor(
        jsonl(List.generate(30, (index) => record('$index'))),
      );
      final header = (await service.getStoreDisplayOnHeader())!;
      final displays = (await service.getStoreDisplays())!;
      expect(header, hasLength(20));
      expect(header.map((store) => store.id).toSet(), hasLength(20));
      expect(displays, hasLength(7));
      expect(
        displays.map((display) => display.f_label),
        MockConfig.displayLabels,
      );
      for (final display in displays) {
        expect(display.store, hasLength(5));
        expect(display.store.map((store) => store.id).toSet(), hasLength(5));
      }
    },
  );

  for (final count in [1, 2, 4, 5, 19, 20]) {
    test('sampling terminates with $count unique source stores', () async {
      final service = serviceFor(
        jsonl(List.generate(count, (index) => record('$index'))),
      );
      final header = (await service.getStoreDisplayOnHeader())!;
      final groups = (await service.getStoreDisplays())!;
      expect(header, hasLength(20));
      expect(
        header.take(count).map((store) => store.id).toSet(),
        hasLength(count),
      );
      expect(header.map((store) => store.id).toSet(), hasLength(count));
      for (final group in groups) {
        expect(group.store, hasLength(5));
        expect(
          group.store.map((store) => store.id).toSet(),
          hasLength(count < 5 ? count : 5),
        );
      }
      final byId = {for (final store in header) store.id: store};
      for (final store in [
        ...header,
        ...groups.expand((group) => group.store),
      ]) {
        expect(identical(store, byId[store.id]), isTrue);
        expect(store.toJson(), byId[store.id]!.toJson());
      }
    });
  }

  test(
    'reproduces all values and selections for the same call sequence',
    () async {
      final text = jsonl(List.generate(30, (index) => record('$index')));
      final first = serviceFor(text);
      final second = serviceFor(text);
      for (var call = 0; call < 3; call++) {
        expect(
          ((await first.getStoreDisplayOnHeader())!).map(
            (store) => store.toJson(),
          ),
          ((await second.getStoreDisplayOnHeader())!).map(
            (store) => store.toJson(),
          ),
        );
        expect(
          ((await first.getStoreDisplays())!).map(
            (display) => display.toJson(),
          ),
          ((await second.getStoreDisplays())!).map(
            (display) => display.toJson(),
          ),
        );
      }
      final different = serviceFor(text, seed: 43);
      expect(
        ((await different.getStoreDisplayOnHeader())!).map(
          (store) => store.toJson(),
        ),
        isNot(
          ((await serviceFor(
            text,
          ).getStoreDisplayOnHeader())!).map((s) => s.toJson()),
        ),
      );
    },
  );

  test(
    'fake fields satisfy ranges, nullability, time and unique-tag rules',
    () async {
      final prices = <String?>{};
      final distances = <double>{};
      var sawNullTime = false;
      var sawTime = false;
      var sawNullTags = false;
      var sawTags = false;
      final text = jsonl(List.generate(20, (index) => record('$index')));
      for (var seed = 0; seed < 30; seed++) {
        for (final store in (await serviceFor(
          text,
          seed: seed,
        ).getStoreDisplayOnHeader())!) {
          expect(MockConfig.priceRanges, contains(store.f_priceRange));
          prices.add(store.f_priceRange);
          expect(store.f_locationRange, inInclusiveRange(0.2, 5.0));
          expect(
            store.f_locationRange * 10,
            closeTo((store.f_locationRange * 10).round(), 1e-9),
          );
          distances.add(store.f_locationRange);
          final time = store.f_deliveryBy;
          if (time == null) {
            sawNullTime = true;
          } else {
            sawTime = true;
            expect(time, matches(RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$')));
          }
          final tags = store.f_tags;
          if (tags == null) {
            sawNullTags = true;
          } else {
            sawTags = true;
            expect(tags.length, inInclusiveRange(1, 4));
            expect(tags.toSet(), hasLength(tags.length));
            expect(tags.every(MockConfig.allowedFakeTags.contains), isTrue);
          }
          expect(store.tags, ['Real source tag']);
        }
      }
      expect(prices, containsAll(MockConfig.priceRanges));
      expect(distances, containsAll([0.2, 5.0]));
      expect([
        sawNullTime,
        sawTime,
        sawNullTags,
        sawTags,
      ], everyElement(isTrue));
    },
  );

  test('preserves metadata and normalizes integer IDs independently', () async {
    final row = record(1175)..['retailer_id'] = 205;
    final store = ((await serviceFor(
      jsonl([row]),
    ).getStoreDisplayOnHeader())!).first;
    expect(store.id, '1175');
    expect(store.retailerId, '205');
    expect(store.backgroundColor, '#aBc123');
    expect(store.name, 'Store 1175');
    expect(store.slug, 'store-1175');
    expect(store.images, ['second-size.png', 'first-size.png']);
    expect(store.tags, ['Real source tag']);
  });

  test(
    'supports shopID while detecting conflicting identifier aliases',
    () async {
      final row = record('007')..remove('shopId');
      row['shopID'] = '007';
      final store = ((await serviceFor(
        jsonl([row]),
      ).getStoreDisplayOnHeader())!).first;
      expect(store.id, '007');
      row['shopId'] = '008';
      await expectLater(
        serviceFor(jsonl([row])).getStoreDisplayOnHeader(),
        throwsA(
          dataError(line: 1, field: 'shopId/shopID', message: 'Conflicting'),
        ),
      );
    },
  );

  test(
    'optional metadata can be absent or null; empty arrays are preserved',
    () async {
      for (final row in [
        <String, Object?>{'shopId': 'a', 'background_color': '#fff'},
        <String, Object?>{
          'shopId': 'a',
          'background_color': '#fff',
          'name': null,
          'slug': null,
          'retailer_id': null,
          'image': null,
          'tags': null,
        },
      ]) {
        final store = ((await serviceFor(
          jsonl([row]),
        ).getStoreDisplayOnHeader())!).first;
        expect([
          store.name,
          store.slug,
          store.retailerId,
          store.images,
          store.tags,
        ], everyElement(isNull));
        expect(
          store.toJson().keys,
          containsAll(['f_priceRange', 'f_deliveryBy', 'f_tags']),
        );
      }
      final row = record('a')
        ..['image'] = <String>[]
        ..['tags'] = <String>[];
      final store = ((await serviceFor(
        jsonl([row]),
      ).getStoreDisplayOnHeader())!).first;
      expect(store.images, isEmpty);
      expect(store.tags, isEmpty);
    },
  );

  test('all returned collection layers are immutable', () async {
    final service = serviceFor(jsonl([record('a')]));
    final header = (await service.getStoreDisplayOnHeader())!;
    final groups = (await service.getStoreDisplays())!;
    expect(() => header.clear(), throwsUnsupportedError);
    expect(() => header[0] = header[1], throwsUnsupportedError);
    expect(() => groups.clear(), throwsUnsupportedError);
    expect(() => groups.first.store.clear(), throwsUnsupportedError);
    expect(() => header.first.images!.clear(), throwsUnsupportedError);
    expect(() => header.first.tags!.clear(), throwsUnsupportedError);
    final fakeTags = header.first.f_tags;
    if (fakeTags != null) {
      expect(() => fakeTags.clear(), throwsUnsupportedError);
    }
  });

  test(
    'entity constructors copy caller lists and debug output cannot mutate them',
    () {
      final images = ['logo'];
      final tags = ['source'];
      final fakeTags = ['EBT'];
      final store = Store(
        id: 'a',
        backgroundColor: '#fff',
        f_priceRange: null,
        f_deliveryBy: null,
        f_locationRange: 0.2,
        images: images,
        tags: tags,
        f_tags: fakeTags,
      );
      final stores = [store];
      final display = StoreDisplay(f_label: 'Example', store: stores);
      images.clear();
      tags.clear();
      fakeTags.clear();
      stores.clear();
      expect(store.images, ['logo']);
      expect(store.tags, ['source']);
      expect(store.f_tags, ['EBT']);
      expect(display.store, [store]);
      expect(() => store.f_tags!.clear(), throwsUnsupportedError);
      (store.toJson()['images']! as List).clear();
      expect(store.images, ['logo']);
      expect(
        jsonDecode(jsonEncode(display.toJson()))['store'][0]['f_deliveryBy'],
        isNull,
      );
    },
  );

  test('blank lines are skipped and identical duplicates collapse regardless of key order', () async {
    final row = record('a');
    final reversed = Map<String, Object?>.fromEntries(
      row.entries.toList().reversed,
    );
    final text =
        '\n${jsonEncode(row)}\n  \n${jsonEncode(reversed)}\n${jsonEncode(record('b'))}\n';
    final header = (await serviceFor(text).getStoreDisplayOnHeader())!;
    expect(header.take(2).map((store) => store.id).toSet(), {'a', 'b'});
    expect(header.map((store) => store.id).toSet(), {'a', 'b'});
  });

  test(
    'duplicate IDs conflict even when an unmapped source field differs',
    () async {
      final first = record('a')..['extra'] = {'value': 1};
      final second = record('a')..['extra'] = {'value': 2};
      await expectLater(
        serviceFor('\n${jsonl([first, second])}').getStoreDisplayOnHeader(),
        throwsA(
          dataError(
            line: 3,
            field: 'shopId',
            message: 'first occurrence at line 2',
          ),
        ),
      );
    },
  );

  for (final text in ['', ' \n\r\n ']) {
    test('empty dataset returns empty responses without padding', () async {
      final service = serviceFor(text);
      expect(await service.getStoreDisplayOnHeader(), isEmpty);
      expect(await service.getStoreDisplays(), isEmpty);
      expect(await service.getAllStores(), isEmpty);
    });
  }

  for (final entry in {
    '{broken': 'Malformed JSON',
    '[]': 'Expected a JSON object',
    'null': 'Expected a JSON object',
  }.entries) {
    test('rejects invalid JSONL record ${entry.key}', () async {
      await expectLater(
        serviceFor('\n${entry.key}').getStoreDisplayOnHeader(),
        throwsA(dataError(line: 2, message: entry.value)),
      );
    });
  }

  final invalidFields = <String, Object?>{
    'shopId': null,
    'background_color': 123,
    'name': 123,
    'slug': false,
    'retailer_id': <String>[],
    'image': 'logo.png',
    'tags': ['valid', 123],
  };
  for (final entry in invalidFields.entries) {
    test('rejects malformed supplied ${entry.key} with provenance', () async {
      final row = record('a')..[entry.key] = entry.value;
      await expectLater(
        serviceFor('\n\n${jsonEncode(row)}').getStoreDisplayOnHeader(),
        throwsA(dataError(line: 3, field: entry.key)),
      );
    });
  }

  test(
    'rejects absent required fields and blank colors or identifiers',
    () async {
      for (final field in ['shopId', 'background_color']) {
        for (final missing in [true, false]) {
          final row = record('a');
          if (missing) {
            row.remove(field);
          } else {
            row[field] = ' ';
          }
          await expectLater(
            serviceFor(jsonl([row])).getStoreDisplayOnHeader(),
            throwsA(dataError(line: 1, field: field)),
          );
        }
      }
    },
  );

  test(
    'concurrent calls and subsequent calls share one initialization',
    () async {
      final source = CountingSource();
      final service = MockDashboardService(dataSource: source, seed: 42);
      final headerFuture = service.getStoreDisplayOnHeader();
      final groupsFuture = service.getStoreDisplays();
      expect(source.loads, 1);
      source.text.complete(jsonl([record('a')]));
      final header = (await headerFuture)!;
      final groups = (await groupsFuture)!;
      expect(identical(header.first, groups.first.store.first), isTrue);
      (await service.getStoreDisplayOnHeader())!;
      expect(source.loads, 1);
    },
  );

  test(
    'failed initialization is cached across concurrent and subsequent calls',
    () async {
      final source = CountingSource();
      final service = MockDashboardService(dataSource: source);
      final first = expectLater(
        service.getStoreDisplayOnHeader(),
        throwsA(dataError(message: 'Unable to load')),
      );
      final second = expectLater(
        service.getStoreDisplays(),
        throwsA(dataError(message: 'Unable to load')),
      );
      source.text.completeError(StateError('read failed'));
      await Future.wait([first, second]);
      await expectLater(
        service.getStoreDisplays(),
        throwsA(dataError(message: 'Unable to load')),
      );
      expect(source.loads, 1);
    },
  );

  test('asset failures identify the asset and setup problem', () async {
    final service = MockDashboardService(
      dataSource: AssetStoreDataSource(
        sourceName: 'missing.jsonl',
        bundle: MissingAssetBundle(),
      ),
    );
    await expectLater(
      service.getStoreDisplays(),
      throwsA(
        isA<MockDataException>()
            .having((error) => error.sourceName, 'source', 'missing.jsonl')
            .having(
              (error) => error.message,
              'message',
              contains('pubspec.yaml'),
            ),
      ),
    );
  });

  test(
    'simulated latency delays responses without changing seeded output',
    () async {
      const delay = Duration(milliseconds: 20);
      final text = jsonl([record('a')]);
      final delayed = MockDashboardService(
        seed: 42,
        latency: delay,
        dataSource: InMemoryStoreDataSource(text),
      );
      final clock = Stopwatch()..start();
      final header = (await delayed.getStoreDisplayOnHeader())!;
      expect(clock.elapsed, greaterThanOrEqualTo(delay));
      expect(
        header.map((store) => store.toJson()),
        ((await serviceFor(
          text,
        ).getStoreDisplayOnHeader())!).map((store) => store.toJson()),
      );
      clock.reset();
      (await delayed.getStoreDisplays())!;
      expect(clock.elapsed, greaterThanOrEqualTo(delay));
      expect(
        () => MockDashboardService(latency: const Duration(microseconds: -1)),
        throwsArgumentError,
      );
    },
  );

  test(
    'real bundled asset maps source identity, colors and metadata faithfully',
    () async {
      final source = AssetStoreDataSource();
      final text = await source.loadStoresText();
      final rows = const LineSplitter()
          .convert(text)
          .where((line) => line.trim().isNotEmpty)
          .map((line) => jsonDecode(line) as Map<String, dynamic>);
      final byId = {for (final row in rows) row['shopId'] as String: row};
      expect(byId.length, greaterThanOrEqualTo(20));
      final DashboardService service = MockDashboardService(seed: 42);
      final header = (await service.getStoreDisplayOnHeader())!;
      final groups = (await service.getStoreDisplays())!;
      expect(header, hasLength(20));
      expect(groups, hasLength(7));
      final seen = <String, Store>{};
      for (final store in [
        ...header,
        ...groups.expand((group) => group.store),
      ]) {
        final row = byId[store.id]!;
        expect(store.backgroundColor, row['background_color']);
        expect(store.name, row['name']);
        expect(store.slug, row['slug']);
        expect(store.retailerId, row['retailer_id']);
        expect(store.images, row['image']);
        expect(store.tags, row['tags']);
        if (seen.containsKey(store.id)) {
          expect(identical(store, seen[store.id]), isTrue);
        }
        seen[store.id] = store;
      }
    },
  );
}

class CountingSource implements StoreDataSource {
  int loads = 0;
  final text = Completer<String>();

  @override
  String get sourceName => 'fixture.jsonl';

  @override
  Future<String> loadStoresText() {
    loads++;
    return text.future;
  }
}

class MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw StateError('Missing asset');
}
