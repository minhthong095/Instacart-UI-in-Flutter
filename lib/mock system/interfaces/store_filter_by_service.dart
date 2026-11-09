import '../entities/carousel.dart';
import '../entities/store.dart';
import '../entities/store_service_display.dart';

abstract interface class StoreFilterByService {
  Future<List<Carousel>?> getCarouselsAtHeader();
  Future<List<StoreServiceDisplay>?> getStoresDisplay();
  Future<List<Store>?> getAllStores();
}
