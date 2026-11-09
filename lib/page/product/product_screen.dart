import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../mock system/data_sources/mock_data_repository.dart';
import '../../mock system/entities/product_display.dart';
import '../../mock system/entities/proudct.dart';
import '../../mock system/entities/store_category.dart';
import '../../mock system/implementations/mock_product_service.dart';
import '../../mock system/interfaces/product_service.dart';
import '../../mock system/entities/store.dart';
import '../capture_support/capture_host.dart';

const _ink = Color(0xFF242529);
const _green = Color(0xFF398622);
const _photoFallback = Color(0xFFF1F2F2);

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final Random _random = Random();
  late MockDataRepository _repository;
  late ProductService _service;
  int _requestGeneration = 0;
  Proudct? _product;
  List<ProductDisplay>? _displays;
  bool _loading = true;
  bool _displayLoading = false;
  String? _loadError;
  String? _displayError;
  int _quantity = 1;
  bool _bookmarked = false;
  int _addedQuantity = 0;
  final Map<String, int> _recommendationQuantities = {};

  @override
  void initState() {
    super.initState();
    _createOwnedServices();
    _loadProduct();
  }

  void _createOwnedServices() {
    _repository = MockDataRepository();
    _service = MockProductService(repository: _repository);
  }

  Future<void> _loadProduct() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _displayLoading = false;
      _loadError = null;
      _displayError = null;
      _product = null;
      _displays = null;
    });

    try {
      final stores = await _repository.stores();
      if (!_isCurrent(generation)) return;
      if (stores == null || stores.isEmpty) {
        _publishUnavailable(generation);
        return;
      }

      final shuffledStores = List<Store>.of(stores)..shuffle(_random);
      for (final store in shuffledStores) {
        final categories = await _repository.categoriesForStore(store.id);
        if (!_isCurrent(generation)) return;
        if (categories == null || categories.isEmpty) continue;

        final candidates = <Proudct>[];
        final seen = <String>{};
        for (final StoreCategory category in categories) {
          for (final product in category.items) {
            if (product == null || product.shopId != store.id) continue;
            final identity = '${product.shopId}\u0000${product.id}';
            if (seen.add(identity)) candidates.add(product);
          }
        }
        candidates.shuffle(_random);

        for (final candidate in candidates) {
          final product = await _service.getProduct(store.id, candidate.id);
          if (!_isCurrent(generation)) return;
          if (product == null) continue;

          setState(() {
            _product = product;
            _loading = false;
            _displayLoading = true;
          });
          try {
            final displays = await _service.getProductDisplay(
              store.id,
              product.id,
            );
            if (!_isCurrent(generation)) return;
            setState(() {
              _displays = displays;
              _displayLoading = false;
            });
          } catch (error) {
            if (!_isCurrent(generation)) return;
            setState(() {
              _displayError = 'Recommendations could not be loaded.';
              _displayLoading = false;
            });
          }
          return;
        }
      }
      _publishUnavailable(generation);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _loading = false;
        _loadError = 'Product details could not be loaded.';
      });
    }
  }

  bool _isCurrent(int generation) =>
      mounted && generation == _requestGeneration;

  void _publishUnavailable(int generation) {
    if (!_isCurrent(generation)) return;
    setState(() {
      _loading = false;
      _product = null;
    });
  }

  Future<void> _retry() async {
    _createOwnedServices();
    _quantity = 1;
    _bookmarked = false;
    _addedQuantity = 0;
    _recommendationQuantities.clear();
    await _loadProduct();
  }

  String _identity(Proudct product) => '${product.shopId}\u0000${product.id}';

  String? _imageUrl(Proudct product) {
    for (final image in product.images) {
      final url = image.url.trim();
      if (url.isNotEmpty) return url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'product',
      backgroundColor: CupertinoColors.white,
      headerBuilder: (context) =>
          SizedBox(height: MediaQuery.paddingOf(context).top),
      contentBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductHero(
            imageUrl: _product == null ? null : _imageUrl(_product!),
            bookmarked: _bookmarked,
            onBookmark: () => setState(() => _bookmarked = !_bookmarked),
          ),
          if (_loading)
            const _StatusMessage('Finding a product…', loading: true)
          else if (_loadError != null)
            _StatusMessage(_loadError!, onRetry: _retry)
          else if (_product == null)
            _StatusMessage(
              'No products are available right now.',
              onRetry: _retry,
            )
          else ...[
            _ProductDetails(product: _product!),
            ..._product!.sections
                .asMap()
                .entries
                .where((entry) {
                  final section = entry.value;
                  return section.headerString.trim().isNotEmpty ||
                      section.bodyString.trim().isNotEmpty;
                })
                .map((entry) {
                  final section = entry.value;
                  return _InformationSection(
                    key: ValueKey('information-${entry.key}'),
                    header: section.headerString,
                    body: section.bodyString,
                  );
                }),
            if (_displayLoading)
              const _StatusMessage('Loading recommendations…', loading: true)
            else if (_displayError != null)
              _StatusMessage(_displayError!)
            else if (_displays == null)
              const _StatusMessage('Recommendations are unavailable.')
            else if (_displays!.isEmpty)
              const _StatusMessage('No recommendations are available.')
            else
              ..._displays!.asMap().entries.map((entry) {
                return _ProductSection(
                  key: ValueKey('recommendation-group-${entry.key}'),
                  display: entry.value,
                  occurrence: entry.key,
                  imageUrlFor: _imageUrl,
                  quantityFor: (product) =>
                      _recommendationQuantities[_identity(product)] ?? 0,
                  onAdd: (product) => setState(() {
                    final key = _identity(product);
                    _recommendationQuantities[key] =
                        (_recommendationQuantities[key] ?? 0) + 1;
                  }),
                );
              }),
          ],
        ],
      ),
      footerBuilder: (context) => _ProductFooter(
        enabled: _product != null,
        quantity: _quantity,
        addedQuantity: _addedQuantity,
        onDecrease: _product == null || _quantity <= 1
            ? null
            : () => setState(() => _quantity--),
        onIncrease: _product == null ? null : () => setState(() => _quantity++),
        onAdd: _product == null
            ? null
            : () => setState(() => _addedQuantity += _quantity),
      ),
    ),
  );
}

class _ProductText extends StatelessWidget {
  const _ProductText(
    this.value, {
    this.size = 13,
    this.weight = FontWeight.w400,
    this.color = _ink,
    this.height = 1.25,
    this.maxLines,
    this.overflow,
  });

  final String value;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
    value,
    maxLines: maxLines,
    overflow: overflow,
    style: TextStyle(
      fontFamily: 'InstacartSansBody',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: 0,
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: onPressed,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 19, color: selected ? _green : _ink),
    ),
  );
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({
    required this.imageUrl,
    required this.bookmarked,
    required this.onBookmark,
  });

  final String? imageUrl;
  final bool bookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 254,
    child: Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              width: 210,
              height: 238,
              child: _ProductImage(url: imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _CircleButton(icon: CupertinoIcons.xmark),
        ),
        Positioned(
          top: 60,
          right: 16,
          child: _CircleButton(
            icon: bookmarked
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            selected: bookmarked,
            onPressed: onBookmark,
          ),
        ),
        const Positioned(
          top: 104,
          right: 16,
          child: _CircleButton(icon: CupertinoIcons.share),
        ),
      ],
    ),
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return const ColoredBox(color: _photoFallback);
    }
    return Image.network(
      value,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: _photoFallback),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: _photoFallback),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Proudct product;

  @override
  Widget build(BuildContext context) {
    final pricingUnit = product.pricingUnit;
    final offer = product.offerLabelString;
    final freeText = product.f_freeText;
    final fullPrice = product.fullPrice;
    final hasPreviousPrice =
        fullPrice != null &&
        fullPrice.trim().isNotEmpty &&
        fullPrice != product.price.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductText(
            product.name,
            size: 21,
            weight: FontWeight.w700,
            height: 1.12,
          ),
          if (pricingUnit != null && pricingUnit.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _ProductText(pricingUnit, size: 13),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProductText(product.price, size: 21, weight: FontWeight.w700),
              if (hasPreviousPrice) ...[
                const SizedBox(width: 8),
                _ProductText(
                  fullPrice,
                  size: 14,
                  color: const Color(0xFF77777B),
                ),
              ],
            ],
          ),
          if (offer != null && offer.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            _OfferPill(label: offer),
          ],
          if (product.f_isManyInStock ||
              (freeText?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (product.f_isManyInStock) const _StockLabel(),
                if (freeText != null && freeText.trim().isNotEmpty)
                  _ProductText(freeText, size: 13, color: _green),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferPill extends StatelessWidget {
  const _OfferPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFDF46),
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    child: _ProductText(label, size: 12.5, weight: FontWeight.w500),
  );
}

class _StockLabel extends StatelessWidget {
  const _StockLabel();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(CupertinoIcons.line_horizontal_3_decrease, size: 13, color: _green),
      SizedBox(width: 5),
      _ProductText(
        'Many in stock',
        size: 13,
        weight: FontWeight.w500,
        color: _green,
      ),
    ],
  );
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    super.key,
    required this.header,
    required this.body,
  });

  final String header;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.trim().isNotEmpty) ...[
          _ProductText(header, size: 16.5, weight: FontWeight.w700),
          if (body.trim().isNotEmpty) const SizedBox(height: 7),
        ],
        if (body.trim().isNotEmpty) _ProductText(body, size: 13.5, height: 1.4),
      ],
    ),
  );
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    super.key,
    required this.display,
    required this.occurrence,
    required this.imageUrlFor,
    required this.quantityFor,
    required this.onAdd,
  });

  final ProductDisplay display;
  final int occurrence;
  final String? Function(Proudct) imageUrlFor;
  final int Function(Proudct) quantityFor;
  final ValueChanged<Proudct> onAdd;

  @override
  Widget build(BuildContext context) {
    final products = display.proudcts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ProductText(
            display.f_label,
            size: 16.5,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 17),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ProductText(
              'No products in this group.',
              color: Color(0xFF727276),
            ),
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return _ProductCard(
                  key: ValueKey(
                    'group-$occurrence-product-$index-${product.shopId}-${product.id}',
                  ),
                  product: product,
                  imageUrl: imageUrlFor(product),
                  quantity: quantityFor(product),
                  onAdd: () => onAdd(product),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.quantity,
    required this.onAdd,
  });

  final Proudct product;
  final String? imageUrl;
  final int quantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final offer = product.offerLabelString;
    final pricingUnit = product.pricingUnit;
    final details = [
      if (pricingUnit != null && pricingUnit.trim().isNotEmpty) pricingUnit,
      if (product.f_isManyInStock) 'Many in stock',
      if ((product.f_freeText?.trim().isNotEmpty ?? false)) product.f_freeText!,
    ].join(' · ');

    return SizedBox(
      width: 142,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _ProductImage(url: imageUrl),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 3,
                  child: _AddButton(onPressed: onAdd, quantity: quantity),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _ProductText(
            product.price,
            size: 18,
            weight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (offer != null && offer.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxWidth: 142),
              color: const Color(0xFFFFDF46),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _ProductText(
                offer,
                size: 11.5,
                weight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const SizedBox(height: 4),
          _ProductText(
            product.name,
            size: 13.5,
            color: const Color(0xFF727276),
            height: 1.3,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          if (details.isNotEmpty)
            _ProductText(
              details,
              size: 11,
              color: const Color(0xFF727276),
              height: 1.2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.quantity});

  final VoidCallback onPressed;
  final int quantity;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: onPressed,
    child: Container(
      width: quantity == 0 ? 36 : 46,
      height: 36,
      decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: quantity == 0
          ? const Icon(
              CupertinoIcons.plus,
              size: 25,
              color: CupertinoColors.white,
            )
          : _ProductText(
              '$quantity +',
              size: 14,
              weight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
    ),
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage(this.message, {this.loading = false, this.onRetry});

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
    child: Column(
      children: [
        if (loading) ...[
          const CupertinoActivityIndicator(),
          const SizedBox(height: 10),
        ],
        _ProductText(message, color: const Color(0xFF727276)),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: onRetry,
            child: const _ProductText(
              'Try again',
              color: _green,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProductFooter extends StatelessWidget {
  const _ProductFooter({
    required this.enabled,
    required this.quantity,
    required this.addedQuantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });

  final bool enabled;
  final int quantity;
  final int addedQuantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      16,
      11,
      16,
      MediaQuery.paddingOf(context).bottom + 12,
    ),
    decoration: const BoxDecoration(
      color: CupertinoColors.white,
      border: Border(top: BorderSide(color: Color(0xFFEDEDEF), width: 1)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onDecrease,
                  child: const Icon(
                    CupertinoIcons.minus,
                    color: Color(0xFF929395),
                    size: 23,
                  ),
                ),
                _ProductText('$quantity', size: 16, weight: FontWeight.w700),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onIncrease,
                  child: const Icon(CupertinoIcons.plus, color: _ink, size: 25),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: onAdd,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled ? _green : const Color(0xFFB8C8B1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: _ProductText(
                addedQuantity == 0 ? 'Add to Cart' : 'Added $addedQuantity',
                size: 19,
                weight: FontWeight.w700,
                color: CupertinoColors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
