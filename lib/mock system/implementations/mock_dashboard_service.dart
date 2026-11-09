import '../data_sources/mock_data_repository.dart';
import '../data_sources/mock_text_data_source.dart';
import '../data_sources/store_data_source.dart';
import '../entities/store.dart';
import '../entities/store_display.dart';
import '../interfaces/dashboard_service.dart';
import '../mock_config.dart';

class MockDashboardService implements DashboardService {
  MockDashboardService({
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
  Future<List<Store>?> getStoreDisplayOnHeader() async {
    await _repository.stores();
    await _wait();
    return _repository.sampleStores(MockConfig.headerCount);
  }

  @override
  Future<List<StoreDisplay>?> getStoreDisplays() async {
    final stores = await _repository.stores();
    await _wait();
    if (stores == null) return null;
    if (stores.isEmpty) return const [];
    final displays = <StoreDisplay>[];
    for (final label in MockConfig.displayLabels) {
      displays.add(
        StoreDisplay(
          f_label: label,
          store: _repository.sample(stores, MockConfig.storesPerDisplay),
        ),
      );
    }
    return List.unmodifiable(displays);
  }

  @override
  Future<List<Store>?> getAllStores() async {
    await _repository.stores();
    await _wait();
    return _repository.sampleStores(MockConfig.allStoresCount);
  }
}
