import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../mock system/data_sources/mock_data_repository.dart';
import '../../mock system/entities/store.dart';
import '../../mock system/entities/store_aisle.dart';
import '../../mock system/implementations/mock_shop_by_aisle_service.dart';
import '../../mock system/interfaces/shop_by_aisle_service.dart';
import '../capture_support/capture_host.dart';

const _ink = Color(0xFF242529);
const _muted = Color(0xFF707178);
const _line = Color(0xFFCECED3);
const _tileBackground = Color(0xFFF7F7F9);
const _green = Color(0xFF087C08);

class ShopByAisleScreen extends StatefulWidget {
  const ShopByAisleScreen({super.key});

  @override
  State<ShopByAisleScreen> createState() => _ShopByAisleScreenState();
}

class _ShopByAisleScreenState extends State<ShopByAisleScreen> {
  final TextEditingController _searchController = TextEditingController();
  late MockDataRepository _repository;
  late ShopByAisleService _service;
  late Random _random;
  Store? _store;
  List<StoreAisle> _aisles = const [];
  bool _loading = true;
  bool _unavailable = false;
  Object? _error;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _createDependencies();
    _loadDiscovery();
  }

  void _createDependencies() {
    _repository = MockDataRepository();
    _random = Random();
    _service = MockShopByAisleService(repository: _repository);
  }

  Future<void> _loadDiscovery({bool recreateDependencies = false}) async {
    final generation = ++_requestGeneration;
    if (recreateDependencies) _createDependencies();
    setState(() {
      _loading = true;
      _unavailable = false;
      _error = null;
      _store = null;
      _aisles = const [];
      _searchController.clear();
    });

    try {
      final stores = await _repository.stores();
      if (!mounted || generation != _requestGeneration) return;
      if (stores == null || stores.isEmpty) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
        return;
      }

      final candidates = List<Store>.of(stores)..shuffle(_random);
      for (final candidate in candidates) {
        final aisles = await _service.getAisles(candidate.id);
        if (!mounted || generation != _requestGeneration) return;
        if (aisles == null) continue;

        if (kDebugMode) {
          final samples = aisles
              .take(3)
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => '${entry.key}:${entry.value.id}:${entry.value.name}',
              )
              .join('|');
          debugPrint(
            'SHOP_BY_AISLE_SELECTION store=${candidate.id} '
            'name=${candidate.name} count=${aisles.length} '
            'imageCount=${aisles.where((aisle) => aisle.imageUrl?.trim().isNotEmpty == true).length} '
            'samples=$samples',
          );
        }

        setState(() {
          _store = candidate;
          _aisles = List<StoreAisle>.unmodifiable(aisles);
          _loading = false;
        });
        return;
      }

      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loading = false;
        _unavailable = true;
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
  void dispose() {
    ++_requestGeneration;
    _searchController.dispose();
    super.dispose();
  }

  List<({StoreAisle aisle, int sourceIndex})> get _visibleAisles {
    final query = _searchController.text.trim().toLowerCase();
    return [
      for (var i = 0; i < _aisles.length; i++)
        if (query.isEmpty || _aisles[i].name.toLowerCase().contains(query))
          (aisle: _aisles[i], sourceIndex: i),
    ];
  }

  Widget _text(
    String value, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    TextAlign align = TextAlign.center,
  }) => Text(
    value,
    textAlign: align,
    style: TextStyle(
      fontFamily: 'InstacartSansBody',
      fontSize: size,
      height: 1.03,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
    ),
  );

  Widget _header() {
    final storeName = _store?.name?.trim();
    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 65,
            child: const Icon(CupertinoIcons.arrow_left, size: 23, color: _ink),
          ),
          Positioned(
            left: 50,
            right: 14,
            top: 54,
            height: 44,
            child: CupertinoTextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              placeholder: storeName?.isNotEmpty == true
                  ? 'Search $storeName...'
                  : 'Search aisles...',
              placeholderStyle: const TextStyle(
                fontFamily: 'InstacartSansBody',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
              style: const TextStyle(
                fontFamily: 'InstacartSansBody',
                fontSize: 14,
                color: _ink,
              ),
              padding: const EdgeInsets.only(left: 5, right: 12),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(CupertinoIcons.search, size: 22, color: _ink),
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aisleTile(StoreAisle aisle, int sourceIndex, double width) {
    final url = aisle.imageUrl?.trim() ?? '';
    final image = url.isEmpty
        ? const _AisleImageFallback()
        : Image.network(
            url,
            width: width,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _AisleImageFallback(),
          );
    return SizedBox(
      key: ValueKey('${_store!.id}:${aisle.id}:$sourceIndex'),
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(width: width, height: 84, child: image),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 45,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                aisle.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'InstacartSansBody',
                  fontSize: 14,
                  height: 1.03,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aisleGrid() => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      const outerPadding = 16.0;
      final width = (constraints.maxWidth - outerPadding * 2 - gap * 3) / 4;
      final items = _visibleAisles;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: outerPadding),
        child: Column(
          children: [
            for (var start = 0; start < items.length; start += 4) ...[
              if (start > 0) const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < 4; column++) ...[
                    if (column > 0) const SizedBox(width: gap),
                    if (start + column < items.length)
                      _aisleTile(
                        items[start + column].aisle,
                        items[start + column].sourceIndex,
                        width,
                      )
                    else
                      SizedBox(width: width),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _statusContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_error != null || _unavailable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 36),
        child: Column(
          children: [
            _text(
              _error != null
                  ? 'We couldn’t load aisles right now.'
                  : 'Aisles are unavailable right now.',
              color: _muted,
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: () => _loadDiscovery(recreateDependencies: true),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_aisles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 36),
        child: _text('No aisles are available for this store.', color: _muted),
      );
    }
    if (_visibleAisles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 36),
        child: _text('No aisles match your search.', color: _muted),
      );
    }
    return _aisleGrid();
  }

  Widget _content() => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 22),
          child: _text(
            'Shop by Aisle',
            size: 21,
            weight: FontWeight.w700,
            align: TextAlign.left,
          ),
        ),
      
        const SizedBox(height: 14),
        _statusContent(),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'shop_by_aisle',
      backgroundColor: CupertinoColors.white,
      headerBuilder: (_) => _header(),
      contentBuilder: (_) => _content(),
    ),
  );
}

class _AisleImageFallback extends StatelessWidget {
  const _AisleImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: _tileBackground,
    child: Center(
      child: Icon(CupertinoIcons.square_grid_2x2, size: 27, color: _line),
    ),
  );
}
