import '../data_sources/mock_data_repository.dart';
import '../data_sources/mock_text_data_source.dart';
import '../data_sources/store_data_source.dart';
import '../entities/carousel.dart';
import '../entities/store.dart';
import '../entities/store_service_display.dart';
import '../interfaces/store_filter_by_service.dart';
import '../mock_config.dart';

class MockStoreFilterByService implements StoreFilterByService {
  MockStoreFilterByService({
    MockDataRepository? repository,
    int? seed,
    StoreDataSource? dataSource,
    MockTextDataSource? textDataSource,
    this.latency = Duration.zero,
  }) : _repository =
           repository ??
           MockDataRepository(
             seed: seed,
             storeDataSource: dataSource,
             textDataSource: textDataSource,
           ) {
    if (latency.isNegative) {
      throw ArgumentError.value(latency, 'latency', 'Must not be negative.');
    }
    if (repository != null &&
        (seed != null || dataSource != null || textDataSource != null)) {
      throw ArgumentError(
        'Configure seed and data sources on the shared repository.',
      );
    }
  }

  final Duration latency;
  final MockDataRepository _repository;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  @override
  Future<List<Carousel>?> getCarouselsAtHeader() async {
    await _wait();
    return _repository.sampleCarousels();
  }

  @override
  Future<List<StoreServiceDisplay>?> getStoresDisplay() async {
    await _wait();
    final stores = await _repository.sampleStores(
      MockConfig.serviceDisplayCount,
    );
    if (stores == null) return null;
    final displays = <StoreServiceDisplay>[];
    for (final store in stores) {
      final label = _repository.nextServiceLabel();
      final products = await _repository.productsForStore(store.id);
      if (products == null) return null;
      displays.add(
        StoreServiceDisplay(f_label: label, store: store, proudcts: products),
      );
    }
    return List.unmodifiable(displays);
  }

  @override
  Future<List<Store>?> getAllStores() async {
    await _wait();
    return _repository.sampleStores(MockConfig.allStoresCount);
  }
}
