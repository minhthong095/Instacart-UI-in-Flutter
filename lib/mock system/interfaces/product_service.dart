import '../entities/proudct.dart';
import '../entities/product_display.dart';

abstract interface class ProductService {
  Future<Proudct?> getProduct(String storeId, String productId);
  Future<List<ProductDisplay>?> getProductDisplay(
    String storeId,
    String productId,
  );
}
