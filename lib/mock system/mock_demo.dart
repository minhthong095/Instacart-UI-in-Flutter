
import 'data_sources/json_support.dart';
import 'mock_system.dart';

/// Debug-only demonstration. Each method is called through its public interface;
/// a failure is reported by the startup wrapper without blocking the widget UI.
Future<void> demonstrateMockServices() async {
  final repository = MockDataRepository(seed: MockConfig.demoSeed);
  final DashboardService dashboard = MockDashboardService(
    repository: repository,
  );
  final StoreFilterByService filter = MockStoreFilterByService(
    repository: repository,
  );
  final StorePage page = MockStorePage(repository: repository);
  final ProductService products = MockProductService(repository: repository);
  final ShopByAisleService aisleService = MockShopByAisleService(
    repository: repository,
  );
  final AisleDetailService detailService = MockAisleDetailService(
    repository: repository,
  );
  final header = await dashboard.getStoreDisplayOnHeader();

  if (header != null && header.isNotEmpty) {

  }


  final filtered = await filter.getStoresDisplay();

  for (final display in filtered ?? <StoreServiceDisplay>[]) {

    if (display.proudcts.isNotEmpty) {

    }
  }
  final stores = await repository.stores();
  if (stores == null || stores.isEmpty) {

    return;
  }
  final storeId = stores.first.id;
  final categories = await page.getCategories(storeId);


  Proudct? anchor;
  StoreCategory? unresolved;
  for (final category in categories ?? <StoreCategory>[]) {
    for (final product in category.items) {
      anchor ??= product;
    }
    if (category.items.contains(null)) unresolved ??= category;
  }
  if (categories != null && categories.isNotEmpty) {
    final category = categories.first;

  }
  if (anchor != null) {
    final product = await products.getProduct(storeId, anchor.id);

    final recommendations = await products.getProductDisplay(
      storeId,
      anchor.id,
    );

  } else {

  }
  if (unresolved != null) {
    final index = unresolved.items.indexOf(null);
    final missingId = unresolved.sourceItemIds[index];


  } else {

  }
  final aisles = await aisleService.getAisles(storeId);

  if (aisles != null && aisles.isNotEmpty) {
    final detail = await detailService.getAisleDetail(storeId, aisles.first.id);
    if (detail != null) {
      final categories = detail.sub.expand((s) => s.categories).toList();
      final slots = categories.expand((c) => c.itemIds).toList();

      if (detail.sub.isNotEmpty) {

      }
      if (categories.isNotEmpty) {
        final category = categories.first;

      }
      final resolved = slots.whereType<Proudct>().firstOrNull;
      if (resolved != null) {

      }
      final issue = categories.expand((c) => c.resolutionIssues).firstOrNull;
      if (issue != null) {

      }
    }
  } else {

  }
  // Derive absent and empty associations from source records instead of invented IDs.
  final source = AssetMockTextDataSource();
  final associated = parseJsonLines(
    await source.loadText(MockConfig.categoryAsset),
    MockConfig.categoryAsset,
  ).map((r) => r.shopId).toSet();
  final missing = stores.where((s) => !associated.contains(s.id)).firstOrNull;
  if (missing != null) {

  } else {

  }
  final empty =
      parseJsonLines(
            await source.loadText(MockConfig.carouselAsset),
            MockConfig.carouselAsset,
          )
          .where(
            (r) =>
                r.objects('carousel').isEmpty &&
                stores.any((s) => s.id == r.shopId),
          )
          .firstOrNull;
  if (empty != null) {

  } else {

  }
  try {
    await page.getCategories(' ');
  } on ArgumentError catch (error) {

  }
}
