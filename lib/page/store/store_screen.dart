import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../mock system/data_sources/mock_data_repository.dart';
import '../../mock system/entities/carousel.dart';
import '../../mock system/entities/proudct.dart';
import '../../mock system/entities/store.dart';
import '../../mock system/entities/store_category.dart';
import '../../mock system/implementations/mock_store_page.dart';
import '../../mock system/interfaces/store_page.dart';
import '../capture_support/capture_host.dart';

const _ink = Color(0xFF242529);
const _muted = Color(0xFF72767B);
const _blue = Color(0xFF2B5F9F);

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.repository});

  /// Optional repository for callers that need to supply their own data source.
  final MockDataRepository? repository;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final Random _random = Random();
  late MockDataRepository _repository;
  late StorePage _storePage;
  bool _ownsRepository = false;
  int _requestGeneration = 0;
  _StoreLoad? _result;
  Object? _error;
  bool _loading = true;
  final Map<(String, String), int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _configureServices();
    _loadStore();
  }

  void _configureServices({bool recreateOwned = false}) {
    _ownsRepository = widget.repository == null;
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else if (recreateOwned || !_ownsRepository) {
      _repository = MockDataRepository();
    } else {
      _repository = MockDataRepository();
    }
    _storePage = MockStorePage(repository: _repository);
  }

  Future<void> _loadStore({bool retry = false}) async {
    final generation = ++_requestGeneration;
    if (retry && _ownsRepository) _configureServices(recreateOwned: true);
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _quantities.clear();
    });
    try {
      final stores = await _repository.stores();
      if (!mounted || generation != _requestGeneration) return;
      if (stores == null) {
        setState(() {
          _loading = false;
          _result = const _StoreLoad.inventoryUnavailable();
        });
        return;
      }
      if (stores.isEmpty) {
        setState(() {
          _loading = false;
          _result = const _StoreLoad.noStores();
        });
        return;
      }

      final candidates = List<Store>.of(stores)..shuffle(_random);
      for (final store in candidates) {
        final responses = await Future.wait<Object?>([
          _storePage.getCarousels(store.id),
          _storePage.getCategories(store.id),
        ]);
        if (!mounted || generation != _requestGeneration) return;
        final carousels = responses[0] as List<Carousel>?;
        final categories = responses[1] as List<StoreCategory>?;
        if (carousels != null || categories != null) {
          setState(() {
            _loading = false;
            _result = _StoreLoad(
              store: store,
              carousels: carousels,
              categories: categories,
            );
          });
          return;
        }
      }
      setState(() {
        _loading = false;
        _result = const _StoreLoad.allUnavailable();
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  void didUpdateWidget(covariant StoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _requestGeneration++;
      _configureServices();
      _loadStore();
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }

  Color _background(Store? store) {
    final value = store?.backgroundColor.trim();
    if (value == null || value.isEmpty) return _blue;
    try {
      final hex = value.replaceFirst('#', '').replaceFirst('0x', '');
      final parsed = int.parse(hex, radix: 16);
      final color = Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
 return color;
    } on FormatException {
      return _blue;
    }
  }

  String _name(Store? store) =>
      store?.name?.trim().isNotEmpty == true ? store!.name!.trim() : 'Store';

  String? _usableImage(Iterable<String?>? values) {
    if (values == null) return null;
    for (final candidate in values) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty && value.startsWith('http')) {
        return value;
      }
    }
    return null;
  }

  Widget _label(
    String text, {
    int maxLines = 2,
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double height = 1.3,
  }) => Text(
    text,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontFamily: 'InstacartSansBody',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    ),
  );

  Widget _header(Store? store) {
    final background = _background(store);
 final titleColor = background.computeLuminance() > 0.179
 ? _ink
 : CupertinoColors.white;
    final actionBackground = background.computeLuminance() > 0.179
        ? const Color(0xFFE7EDF4)
        : const Color(0xFF23558E);
    final logo = _usableImage(store?.images);
    final name = _name(store);
    return Container(
      height: 187,
      color: background,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 67,
            child: _headerCircle(
              CupertinoIcons.arrow_left,
              background: actionBackground,
              foreground: titleColor,
              size: 40,
            ),
          ),
          Positioned(
            left: 64,
            top: 69,
            width: 48,
            height: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: logo == null
                  ? const ColoredBox(color: Color(0xFFE7EDF4))
                  : Image.network(
                      logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFFE7EDF4)),
                    ),
            ),
          ),
          Positioned(
            left: 124,
            top: 64,
            width: 150,
            child: _label(
              name,
              maxLines: 1,
              size: 16,
              weight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          if (store?.f_deliveryBy?.trim().isNotEmpty == true)
            Positioned(
              left: 124,
              top: 88,
              width: 150,
              child: _label(
                'Delivery by ${store!.f_deliveryBy!.trim()}',
                size: 11,
                color: titleColor,
              ),
            ),
          Positioned(
            right: 68,
            top: 67,
            child: _headerCircle(
              CupertinoIcons.person_badge_plus_fill,
              background: actionBackground,
              foreground: titleColor,
              size: 40,
            ),
          ),
          Positioned(
            right: 16,
            top: 67,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB6C9DB)),
              ),
              child: const Icon(
                CupertinoIcons.leaf_arrow_circlepath,
                color: Color(0xFFF68B30),
                size: 26,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 127,
            height: 48,
            child: CupertinoTextField(
              readOnly: true,
              placeholder: 'Search ${name == 'Store' ? 'products' : name}...',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 13, right: 5),
                child: Icon(CupertinoIcons.search, size: 22, color: _ink),
              ),
              placeholderStyle: const TextStyle(
                fontFamily: 'InstacartSansBody',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              style: const TextStyle(
                fontFamily: 'InstacartSansBody',
                fontSize: 14,
                color: _ink,
              ),
              padding: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                border: Border.all(color: const Color(0xFFCFD0D3)),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCircle(
    IconData icon, {
    required Color background,
    required Color foreground,
    required double size,
  }) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, size: size * 0.62, color: foreground),
  );

  Widget _carouselRail(List<Carousel>? carousels) {
    if (carousels == null) return _unavailable('Shortcuts unavailable');
    if (carousels.isEmpty) return _empty('No shortcuts available');
    return SizedBox(
      height: 123,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: carousels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final carousel = carousels[index];
          final image = carousel.image.trim();
          return SizedBox(
            width: 76,
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: image.isEmpty
                      ? const Icon(CupertinoIcons.arrow_up_right, color: _muted)
                      : Image.network(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(CupertinoIcons.photo, color: _muted),
                        ),
                ),
                const SizedBox(height: 5),
                _label(
                  carousel.name.trim().isNotEmpty
                      ? carousel.name.trim()
                      : 'Shortcut',
                  size: 12,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _artwork(Proudct product) {
    final image = _usableImage(product.images.map((item) => item.url));
    return SizedBox(
      height: 136,
      width: 136,
      child: image == null
          ? const Center(
              child: Icon(
                CupertinoIcons.photo,
                size: 38,
                color: Color(0xFFB7BBC0),
              ),
            )
          : Image.network(
              image,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  size: 38,
                  color: Color(0xFFB7BBC0),
                ),
              ),
            ),
    );
  }

  Widget _productCard(Proudct product, int slotIndex) {
    final key = (product.shopId, product.id);
    final quantity = _quantities[key] ?? 0;
    final previous = product.fullPrice?.trim();
    final offer = product.offerLabelString?.trim();
    final freeText = product.f_freeText?.trim();
    final pricingUnit = product.pricingUnit?.trim();
    return SizedBox(
      key: ValueKey('product-${product.shopId}-${product.id}-$slotIndex'),
      width: 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 142,
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, child: _artwork(product)),
                Positioned(
                  right: 0,
                  top: 2,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () =>
                        setState(() => _quantities[key] = quantity + 1),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF438B2B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        quantity > 0
                            ? CupertinoIcons.check_mark
                            : CupertinoIcons.plus,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            product.price,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'InstacartSansBody',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          if (previous != null &&
              previous.isNotEmpty &&
              previous != product.price)
            Text(
              previous,
              style: const TextStyle(
                fontFamily: 'InstacartSansBody',
                fontSize: 12,
                color: _muted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          const SizedBox(height: 3),
          SizedBox(
            height: 37,
            child: _label(
              product.name.trim().isNotEmpty ? product.name.trim() : 'Product',
              size: 13,
              color: _muted,
              height: 1.35,
            ),
          ),
          if (offer != null && offer.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: const Color(0xFFFFDD00),
              child: _label(offer, size: 11),
            ),
          if (pricingUnit != null && pricingUnit.isNotEmpty)
            _label(pricingUnit, size: 12, color: _muted),
          if (freeText != null && freeText.isNotEmpty)
            _label(freeText, size: 12, color: _muted),
          if (product.f_isManyInStock)
            _label('Many in stock', size: 12, color: const Color(0xFF347824)),
          if (quantity > 0) _label('Added: $quantity', size: 12, color: _muted),
        ],
      ),
    );
  }

  Widget _categorySection(StoreCategory category, int occurrenceIndex) {
    final title = category.title.trim();
    final slots = category.items;
    final resolvedCount = slots.whereType<Proudct>().length;
    var railHeight = 260.0;
    for (final product in slots.whereType<Proudct>()) {
      var cardHeight = 142.0 + (product.price.length > 10 ? 46 : 27) + 3 + 37;
      if (product.fullPrice?.trim().isNotEmpty == true &&
          product.fullPrice!.trim() != product.price) {
        cardHeight += 16;
      }
      if (product.offerLabelString?.trim().isNotEmpty == true) cardHeight += 19;
      if (product.pricingUnit?.trim().isNotEmpty == true) cardHeight += 16;
    if (product.f_freeText?.trim().isNotEmpty == true) {
      cardHeight += product.f_freeText!.trim().length > 18 ? 32 : 16;
    }
      if (product.f_isManyInStock) cardHeight += 16;
      if ((_quantities[(product.shopId, product.id)] ?? 0) > 0) {
        cardHeight += 16;
      }
    railHeight = max(railHeight, cardHeight).toDouble();
    }
    return Padding(
      key: ValueKey(
        'category-${category.shopId}-${category.categoryId}-$occurrenceIndex',
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _label(
              title.isNotEmpty ? title : 'Products',
              size: 21,
              weight: FontWeight.w700,
            ),
          ),
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No products in this section',
                style: TextStyle(color: _muted),
              ),
            )
          else if (resolvedCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Items unavailable (${category.resolutionIssues.length} unresolved)',
                style: const TextStyle(color: _muted),
              ),
            )
          else
            SizedBox(
              height: railHeight,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: slots.length,
                itemBuilder: (context, slotIndex) {
                  final product = slots[slotIndex];
                  if (product == null) return const SizedBox(width: 8);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _productCard(product, slotIndex),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _unavailable(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Text(text, style: const TextStyle(color: _muted)),
  );

  Widget _empty(String text) => _unavailable(text);

  Widget _body() {
    if (_loading) return const Center(child: CupertinoActivityIndicator());
    if (_error != null) {
      return _status('Store data could not be loaded.', retry: true);
    }
    final result = _result!;
    if (result.store == null) return _status(result.message!, retry: true);
    final categories = result.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (result.store!.f_deliveryBy == null) const SizedBox(height: 2),
        if (result.carousels == null)
          _unavailable('Shortcuts unavailable')
        else
          _carouselRail(result.carousels),
        if (categories == null)
          _unavailable('Product categories unavailable')
        else if (categories.isEmpty)
          _empty('No product categories available')
        else
          for (var index = 0; index < categories.length; index++)
            _categorySection(categories[index], index),
        const SizedBox(height: 112),
      ],
    );
  }

  Widget _status(String message, {bool retry = false}) => SizedBox(
    height: 280,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message, textAlign: TextAlign.center),
          ),
          if (retry)
            CupertinoButton.filled(
              onPressed: () => _loadStore(retry: true),
              child: const Text('Retry'),
            ),
        ],
      ),
    ),
  );

  int get _cartCount => _quantities.values.fold(0, (sum, value) => sum + value);

  Widget _cart() => Container(
    height: 99,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 33),
    alignment: Alignment.topCenter,
    child: Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF31721F),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Cart',
            style: TextStyle(
              fontFamily: 'InstacartSansBody',
              color: CupertinoColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_cartCount > 0)
            Text(
              '$_cartCount items',
              style: const TextStyle(color: CupertinoColors.white),
            ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.cart,
            size: 25,
            color: CupertinoColors.white,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'store',
      backgroundColor: CupertinoColors.white,
      contentBuilder: (_) => _body(),
      headerBuilder: (_) => _header(_result?.store),
      overlayBuilder: (_) => _cart(),
      overlayHeight: 99,
    ),
  );
}

class _StoreLoad {
  const _StoreLoad({required this.store, this.carousels, this.categories})
    : message = null;
  const _StoreLoad.inventoryUnavailable()
    : store = null,
      carousels = null,
      categories = null,
      message = 'Store list unavailable.';
  const _StoreLoad.noStores()
    : store = null,
      carousels = null,
      categories = null,
      message = 'No stores are available.';
  const _StoreLoad.allUnavailable()
    : store = null,
      carousels = null,
      categories = null,
      message = 'Store content is unavailable.';

  final Store? store;
  final List<Carousel>? carousels;
  final List<StoreCategory>? categories;
  final String? message;
}
