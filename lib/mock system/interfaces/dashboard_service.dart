import '../entities/store.dart';
import '../entities/store_display.dart';

abstract interface class DashboardService {
  Future<List<Store>?> getStoreDisplayOnHeader();
  Future<List<StoreDisplay>?> getStoreDisplays();
  Future<List<Store>?> getAllStores();
}
