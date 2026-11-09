import '../data_sources/mock_data_repository.dart';
import '../data_sources/mock_text_data_source.dart';
import '../data_sources/store_data_source.dart';
import '../entities/carousel.dart';
import '../entities/store_category.dart';
import '../interfaces/store_page.dart';

class MockStorePage implements StorePage {
  MockStorePage({
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
  Future<List<Carousel>?> getCarousels(String storeId) async {
    await _wait();
    return _repository.carouselsForStore(storeId);
  }

  @override
  Future<List<StoreCategory>?> getCategories(String storeId) async {
    await _wait();
    return _repository.categoriesForStore(storeId);
  }
}
