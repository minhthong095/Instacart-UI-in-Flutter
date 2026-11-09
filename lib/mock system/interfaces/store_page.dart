import '../entities/carousel.dart';
import '../entities/store_category.dart';

abstract interface class StorePage {
  Future<List<Carousel>?> getCarousels(String storeId);
  Future<List<StoreCategory>?> getCategories(String storeId);
}
