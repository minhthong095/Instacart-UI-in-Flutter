import '../data_sources/mock_data_repository.dart';
import '../data_sources/mock_text_data_source.dart';
import '../data_sources/store_data_source.dart';
import '../entities/proudct.dart';
import '../entities/product_display.dart';
import '../interfaces/product_service.dart';

class MockProductService implements ProductService {
  MockProductService({
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
  Future<Proudct?> getProduct(String storeId, String productId) async {
    await _wait();
    return _repository.product(storeId, productId);
  }

  @override
  Future<List<ProductDisplay>?> getProductDisplay(
    String storeId,
    String productId,
  ) async {
    await _wait();
    return _repository.productDisplays(storeId, productId);
  }
}
