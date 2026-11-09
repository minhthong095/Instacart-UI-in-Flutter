import '../entities/store_aisle.dart';

abstract interface class ShopByAisleService {
  Future<List<StoreAisle>?> getAisles(String storeId);
}
