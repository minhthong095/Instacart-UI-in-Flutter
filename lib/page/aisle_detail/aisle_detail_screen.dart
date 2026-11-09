import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../mock system/data_sources/mock_data_repository.dart';
import '../../mock system/entities/aisle_sub.dart';
import '../../mock system/entities/aisle_sub_category.dart';
import '../../mock system/entities/proudct.dart';
import '../../mock system/entities/store.dart';
import '../../mock system/entities/store_aisle.dart';
import '../../mock system/entities/store_aisle_detail.dart';
import '../../mock system/implementations/mock_aisle_detail_service.dart';
import '../../mock system/implementations/mock_shop_by_aisle_service.dart';
import '../../mock system/interfaces/aisle_detail_service.dart';
import '../../mock system/interfaces/shop_by_aisle_service.dart';
import '../capture_support/capture_host.dart';

const _ink = Color(0xFF252629);
const _muted = Color(0xFF686A6E);
const _green = Color(0xFF3D8825);

typedef ProductAddCallback = void Function(String shopId, String productId);
typedef StoreDiscoveryLoader = Future<List<Store>?> Function();

class AisleDetailScreen extends StatefulWidget {
  const AisleDetailScreen({
    super.key,
    this.repository,
    this.aisleService,
    this.detailService,
    this.random,
    this.onAddProduct,
    this.storeLoader,
  });

  final MockDataRepository? repository;
  final ShopByAisleService? aisleService;
  final AisleDetailService? detailService;
  final Random? random;
  final ProductAddCallback? onAddProduct;
  final StoreDiscoveryLoader? storeLoader;

  @override
  State<AisleDetailScreen> createState() => _AisleDetailScreenState();
}

class _AisleDetailScreenState extends State<AisleDetailScreen> {
  final _tabsController = ScrollController();
  final _chipsController = ScrollController();
  final _tabsViewportKey = GlobalKey();
  final _chipsViewportKey = GlobalKey();
  final _pageController = ScrollController();
  MockDataRepository? _repository;
  ShopByAisleService? _aisleService;
  AisleDetailService? _detailService;
  Random? _random;
  _AisleLoad? _load;
  Object? _loadError;
  bool _loading = true;
  int _requestGeneration = 0;
  int? _selectedSubIndex;
  (int, int)? _selectedCategoryPath;

  @override
  void initState() {
    super.initState();
    _configureAndLoad();
  }

  @override
  void didUpdateWidget(covariant AisleDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.aisleService != widget.aisleService ||
        oldWidget.detailService != widget.detailService ||
        oldWidget.random != widget.random ||
        oldWidget.storeLoader != widget.storeLoader) {
      _configureAndLoad();
    }
  }

  void _configureAndLoad() {
    final repository = widget.repository ?? MockDataRepository();
    _repository = repository;
    _aisleService =
        widget.aisleService ?? MockShopByAisleService(repository: repository);
    _detailService =
        widget.detailService ?? MockAisleDetailService(repository: repository);
    _random = widget.random ?? Random();
    _loadHierarchy(++_requestGeneration);
  }

  Future<void> _loadHierarchy(int generation) async {
    setState(() {
      _loading = true;
      _load = null;
      _loadError = null;
      _selectedSubIndex = null;
      _selectedCategoryPath = null;
    });

    try {
      final stores = await (widget.storeLoader ?? _repository!.stores)();
      if (!_isCurrent(generation)) return;
      if (stores == null || stores.isEmpty) {
        _finishUnavailable(generation);
        return;
      }
      final candidates = List<Store>.of(stores)..shuffle(_random);
      for (final store in candidates) {
        final aisles = await _aisleService!.getAisles(store.id);
        if (!_isCurrent(generation)) return;
        if (aisles == null || aisles.isEmpty) continue;
        final shuffledAisles = List<StoreAisle>.of(aisles)..shuffle(_random);
        for (final aisle in shuffledAisles) {
          final detail = await _detailService!.getAisleDetail(
            store.id,
            aisle.id,
          );
          if (!_isCurrent(generation)) return;
          if (detail == null) continue;

          setState(() {
            _load = _AisleLoad(
              storeId: store.id,
              storeName: store.name,
              aisleId: aisle.id,
              aisleName: aisle.name,
              detail: detail,
            );
            _loading = false;
            _selectedSubIndex = detail.sub.isEmpty ? null : 0;
            _selectedCategoryPath = null;
          });
          return;
        }
      }
      _finishUnavailable(generation);
    } catch (error) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _isCurrent(int generation) =>
      mounted && generation == _requestGeneration;

  void _finishUnavailable(int generation) {
    if (!_isCurrent(generation)) return;
    setState(() => _loading = false);
  }

  List<_AisleSection> _sections() {
    final detail = _load?.detail;
    if (detail == null) return const [];
    final result = <_AisleSection>[];
    final firstSub = _selectedSubIndex ?? 0;
    final lastSub = _selectedSubIndex ?? detail.sub.length - 1;
    for (var subIndex = firstSub; subIndex <= lastSub; subIndex++) {
      final sub = detail.sub[subIndex];
      for (
        var categoryIndex = 0;
        categoryIndex < sub.categories.length;
        categoryIndex++
      ) {
        final category = sub.categories[categoryIndex];
        final title = category.title?.trim();
        result.add(
          _AisleSection(
            subIndex: subIndex,
            categoryIndex: categoryIndex,
            sub: sub,
            category: category,
            title: title == null || title.isEmpty ? sub.name : title,
            products: category.itemIds.whereType<Proudct>().toList(),
          ),
        );
      }
    }
    return result;
  }

  List<_AisleSection> get _namedSections =>
      _sections().where((section) => _hasTitle(section.category)).toList();

  bool _hasTitle(AisleSubCategory category) =>
      category.title?.trim().isNotEmpty ?? false;

  List<_AisleSection> get _visibleSections {
    final all = _sections();
    final selectedPath = _selectedCategoryPath;
    if (selectedPath != null) {
      final selectedSection = all.where(
        (section) =>
            section.subIndex == selectedPath.$1 &&
            section.categoryIndex == selectedPath.$2,
      );
      if (selectedSection.isEmpty || selectedSection.first.products.isEmpty) {
        return const [];
      }
      return [selectedSection.first];
    }
    return all.where((section) => section.products.isNotEmpty).toList();
  }

  String get _heading {
    final detail = _load?.detail;
    final index = _selectedSubIndex;
    if (detail == null) return '';
    if (index == null || index >= detail.sub.length) return detail.name;
    return detail.sub[index].name;
  }

  void _selectSub(int? index) {
    setState(() {
      _selectedSubIndex = index;
      _selectedCategoryPath = null;
    });
    _resetBodyAndChips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealSelected(
        index == null ? 'tab-all' : 'tab-$index',
        _tabsViewportKey,
      );
    });
  }

  void _selectCategory((int, int)? path) {
    setState(() => _selectedCategoryPath = path);
    _resetBodyAndChips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = path == null ? 'chip-all' : 'chip-${path.$1}-${path.$2}';
      _revealSelected(key, _chipsViewportKey);
    });
  }

  void _resetBodyAndChips() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpTo(0);
      if (_chipsController.hasClients) _chipsController.jumpTo(0);
    });
  }

  void _revealSelected(String key, GlobalKey viewportKey) {
    if (!mounted) return;
    final itemContext = _itemKeys[key]?.currentContext;
    final viewportContext = viewportKey.currentContext;
    if (itemContext == null || viewportContext == null) return;
    final itemObject = itemContext.findRenderObject();
    final viewportObject = viewportContext.findRenderObject();
    if (itemObject is! RenderBox || viewportObject is! RenderBox) return;
    final controller = _scrollControllerFor(viewportKey);
    if (!controller.hasClients) return;
    final itemLeft = itemObject
        .localToGlobal(Offset.zero, ancestor: viewportObject)
        .dx;
    final itemRight = itemLeft + itemObject.size.width;
    final max = controller.position.maxScrollExtent;
    double? target;
    if (itemLeft < 0) {
      target = controller.offset + itemLeft;
    } else if (itemRight > viewportObject.size.width) {
      target = controller.offset + itemRight - viewportObject.size.width;
    }
    if (target != null) {
      controller.animateTo(
        target.clamp(0, max),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  final Map<String, GlobalKey> _itemKeys = {};

  ScrollController _scrollControllerFor(GlobalKey key) =>
      key == _tabsViewportKey ? _tabsController : _chipsController;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'aisle_detail',
      backgroundColor: CupertinoColors.white,
      controller: _pageController,
      headerBuilder: (context) => _HeaderView(this),
      contentBuilder: (context) => _ContentView(this),
      footerBuilder: (context) => _FooterView(),
    ),
  );

  String? _nonblank(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  @override
  void dispose() {
    _requestGeneration++;
    _tabsController.dispose();
    _chipsController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class _AisleLoad {
  const _AisleLoad({
    required this.storeId,
    required this.storeName,
    required this.aisleId,
    required this.aisleName,
    required this.detail,
  });

  final String storeId;
  final String? storeName;
  final String aisleId;
  final String aisleName;
  final StoreAisleDetail detail;
}

class _AisleSection {
  const _AisleSection({
    required this.subIndex,
    required this.categoryIndex,
    required this.sub,
    required this.category,
    required this.title,
    required this.products,
  });

  final int subIndex;
  final int categoryIndex;
  final AisleSub sub;
  final AisleSubCategory category;
  final String title;
  final List<Proudct> products;
}

class _TextView extends StatelessWidget {
  const _TextView(this.text, {this.size = 13, this.color = _ink, this.weight = .w400, this.underline = false, this.maxLines = 1, this.overflow = .ellipsis});
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;
  final bool underline;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: overflow,
    style: TextStyle(
      fontFamily: '.SF Pro Text',
      fontSize: size,
      height: 1.35,
      color: color,
      fontWeight: weight,
      decoration: underline ? .underline : null,
    ),
  );
}

class _ButtonView extends StatelessWidget {
  const _ButtonView(this.label, this.child, {this.onPressed});
  final String label;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed ?? () {},
        child: Semantics(label: label, button: true, child: child),
      );
}

class _HeaderView extends StatelessWidget {
  const _HeaderView(this.owner);

  final _AisleDetailScreenState owner;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(height: MediaQuery.paddingOf(context).top),
      SizedBox(
        height: 57,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: _ButtonView(
                'Back',
                const Icon(CupertinoIcons.arrow_left, size: 24, color: _ink),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 44,
                child: CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  placeholder: 'Search Target...',
                  placeholderStyle: const TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 13,
                    color: _ink,
                    fontWeight: .w500,
                  ),
                  style: const TextStyle(fontSize: 13, color: _ink),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 13),
                    child: Icon(CupertinoIcons.search, size: 23, color: _ink),
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border.all(color: const Color(0xFFCCCCD0)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      SizedBox(
        height: 43,
        child: Align(
          alignment: .topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: _TextView(
              owner._loading ? '' : owner._heading,
              size: 20,
              weight: .w700,
              color: CupertinoColors.black,
            ),
          ),
        ),
      ),
      SizedBox(
        height: 40,
        child: owner._load == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                key: owner._tabsViewportKey,
                controller: owner._tabsController,
                scrollDirection: .horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _TabView(owner,
                      keyName: 'tab-all',
                      label: 'All ${owner._load!.detail.name}',
                      selected: owner._selectedSubIndex == null,
                      onPressed: () => owner._selectSub(null),
                    ),
                    for (var i = 0; i < owner._load!.detail.sub.length; i++)
                      _TabView(owner,
                        keyName: 'tab-$i',
                        label: owner._load!.detail.sub[i].name,
                        selected: owner._selectedSubIndex == i,
                        onPressed: () => owner._selectSub(i),
                      ),
                  ],
                ),
              ),
      ),
      Container(height: 1, color: const Color(0xFFE8E8EA)),
    ],
  );
}

class _TabView extends StatelessWidget {
  const _TabView(this.owner, {required this.keyName, required this.label, required this.selected, required this.onPressed});

  final _AisleDetailScreenState owner;
  final String keyName;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final itemKey = owner._itemKeys.putIfAbsent(keyName, GlobalKey.new);
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        key: itemKey,
        behavior: .opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 12),
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: .centerLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: _TextView(
                    label,
                    color: selected ? _ink : const Color(0xFF777A80),
                    weight: .w600,
                  ),
                ),
                if (selected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 2,
                    child: const ColoredBox(color: _ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView(this.owner);

  final _AisleDetailScreenState owner;

  @override
  Widget build(BuildContext context) {
    if (owner._loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (owner._loadError != null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('Aisle details could not be loaded.')),
      );
    }
    if (owner._load == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No aisle details are available.')),
      );
    }

    final categories = owner._namedSections;
    final sections = owner._visibleSections;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 32,
          child: SingleChildScrollView(
            key: owner._chipsViewportKey,
            controller: owner._chipsController,
            scrollDirection: .horizontal,
            child: Row(
              children: [
                const SizedBox(width: 20),
                _ChipView(owner,
                  keyName: 'chip-all',
                  label: 'All',
                  selected: owner._selectedCategoryPath == null,
                  onPressed: () => owner._selectCategory(null),
                ),
                for (final section in categories)
                  _ChipView(owner,
                    keyName:
                        'chip-${section.subIndex}-${section.categoryIndex}',
                    label: section.category.title!.trim(),
                    selected:
                        owner._selectedCategoryPath ==
                        (section.subIndex, section.categoryIndex),
                    onPressed: () => owner._selectCategory((
                      section.subIndex,
                      section.categoryIndex,
                    )),
                  ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        if (sections.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text('No products are available in this category.'),
          )
        else
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _SectionView(owner, sections[i]),
            const SizedBox(height: 8),
            _RailView(owner, sections[i]),
          ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ChipView extends StatelessWidget {
  const _ChipView(this.owner, {required this.keyName, required this.label, required this.selected, required this.onPressed});

  final _AisleDetailScreenState owner;
  final String keyName;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final itemKey = owner._itemKeys.putIfAbsent(keyName, GlobalKey.new);
    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          key: itemKey,
          behavior: .opaque,
          onTap: onPressed,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: .center,
            decoration: BoxDecoration(
              color: selected ? _ink : const Color(0xFFE8E8EA),
              borderRadius: BorderRadius.circular(22),
            ),
            child: _TextView(
              label,
              color: selected ? CupertinoColors.white : _ink,
              weight: .w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView(this.owner, this.section);

  final _AisleDetailScreenState owner;
  final _AisleSection section;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 20),
    child: Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(
          child: _TextView(section.title, size: 20, weight: .w700),
        ),
        _ButtonView(
          'View more ${section.title}',
          Row(
            mainAxisSize: .min,
            children: [
              _TextView('View more', weight: .w600, underline: true),
              const SizedBox(width: 3),
              const Icon(CupertinoIcons.chevron_right, size: 13, color: _ink),
            ],
          ),
          onPressed: () =>
              owner._selectCategory((section.subIndex, section.categoryIndex)),
        ),
      ],
    ),
  );
}

class _RailView extends StatelessWidget {
  const _RailView(this.owner, this.section);

  final _AisleDetailScreenState owner;
  final _AisleSection section;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 250,
    child: ListView.separated(
      key: ValueKey('rail-${section.subIndex}-${section.categoryIndex}'),
      scrollDirection: .horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16),
      itemCount: section.products.length,
      separatorBuilder: (_, _) => const SizedBox(width: 17),
      itemBuilder: (context, index) => _ProductView(owner,
        section.products[index],
        key: ValueKey(
          'product-${section.subIndex}-${section.categoryIndex}-$index',
        ),
      ),
    ),
  );
}

class _ProductView extends StatelessWidget {
  const _ProductView(this.owner, this.product, {super.key});

  final _AisleDetailScreenState owner;
  final Proudct product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            height: 124,
            child: Stack(
              children: [
                Positioned(
                  left: 1,
                  top: 14,
                  width: 134,
                  height: 104,
                  child: _ArtworkView(product),
                ),
                Positioned(
                  right: 1,
                  top: 0,
                  child: _ButtonView(
                    'Add ${product.name}',
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: .circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        size: 28,
                        color: CupertinoColors.white,
                      ),
                    ),
                    onPressed: () =>
                        owner.widget.onAddProduct?.call(product.shopId, product.id),
                  ),
                ),
                if (owner._nonblank(product.offerLabelString) case final offer?)
                  Positioned(left: 0, bottom: 0, child: _BadgeView(offer)),
              ],
            ),
          ),
          _PriceView(product.price),
          _TextView(product.name, color: _muted, maxLines: 2),
          if (owner._nonblank(product.pricingUnit) case final unit?)
            _TextView(unit, color: _muted),
          if (owner._nonblank(product.f_freeText) case final freeText?)
            _TextView(freeText, color: _muted),
          if (product.f_isManyInStock)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.line_horizontal_3_decrease,
                    size: 15,
                    color: _green,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: _TextView('Many in stock', weight: .w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeView extends StatelessWidget {
  const _BadgeView(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 112),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFF343537),
      borderRadius: BorderRadius.circular(4),
    ),
    child: _TextView(label, size: 11, color: CupertinoColors.white),
  );
}

class _ArtworkView extends StatelessWidget {
  const _ArtworkView(this.product);
  final Proudct product;

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    for (final image in product.images) {
      final uri = Uri.tryParse(image.url.trim());
      if (uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty) {
        imageUrl = uri.toString();
        break;
      }
    }
    if (imageUrl == null) {
      return const Center(
        child: Icon(CupertinoIcons.photo, size: 26, color: Color(0xFFB8BABD)),
      );
    }

    return Image.network(
      imageUrl,
      fit: .contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(CupertinoIcons.photo, size: 26, color: Color(0xFFB8BABD)),
      ),
    );
  }
}

class _PriceView extends StatelessWidget {
  const _PriceView(this.source);
  final String source;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^(.*?)(\d+)([.,]\d{2})$').firstMatch(source.trim());
    if (match == null) {
      return _TextView(source, size: 17, weight: .w700);
    }
    return SizedBox(
      height: 25,
      child: Row(
        crossAxisAlignment: .start,
        children: [
          if (match.group(1)!.isNotEmpty)
            _TextView(match.group(1)!, weight: .w700),
          _TextView(match.group(2)!, size: 20, weight: .w700),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _TextView(match.group(3)!, weight: .w700),
          ),
        ],
      ),
    );
  }
}

class _FooterView extends StatelessWidget {
  const _FooterView();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.paddingOf(context).bottom,
    ),
    child: _ButtonView(
      'View cart, 3 items',
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF2D711C),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _TextView(
              'View cart',
              color: CupertinoColors.white,
              weight: .w600,
            ),
            const Spacer(),
            const Icon(
              CupertinoIcons.cart_fill,
              color: CupertinoColors.white,
              size: 23,
            ),
            const SizedBox(width: 8),
            _TextView(
              '3',
              size: 15,
              color: CupertinoColors.white,
              weight: .w700,
            ),
          ],
        ),
      ),
    ),
  );
}
