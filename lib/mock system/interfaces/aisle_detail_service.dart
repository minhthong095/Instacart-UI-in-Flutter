import '../entities/store_aisle_detail.dart';

abstract interface class AisleDetailService {
  Future<StoreAisleDetail?> getAisleDetail(String storeId, String aisleId);
}
