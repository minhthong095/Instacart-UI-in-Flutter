import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../capture_support/capture_host.dart';
import '../../mock system/mock_system.dart';
import 'dashboard_bloc.dart';

const _ink = Color(0xFF242529);
const _gray = Color(0xFF65686D);
const _yellow = Color(0xFFFFDF00);

/// Service-backed dashboard using the supplied reference styling.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.service});

  final DashboardService? service;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DashboardBloc(service: service ?? MockDashboardService())
          ..add(const DashboardStarted()),
    child: BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        child: CaptureHost.lazy(
          screenId: 'dashboard',
          backgroundColor: CupertinoColors.white,
          headerBuilder: (context) => _DashboardHeader(MediaQuery.paddingOf(context).top),
          scrollableBuilder: (context, controller) {
            if (state is! DashboardLoaded) return const SizedBox.shrink();
            final items = _content(state);
            return ListView.builder(
              controller: controller,
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: .onDrag,
              itemCount: items.length,
              itemBuilder: (_, index) => items[index](),
            );
          },
        ),
      ),
    ),
  );

  List<Widget Function()> _content(DashboardLoaded state) => [
    () => const _DashboardFilters(),
    if (state.headerStores.isNotEmpty)
      () => _StoreGrid(state.headerStores, state.allStores.length),
    for (final display in state.displays)
      if (display.store.isNotEmpty) ...[
        if (display.f_label.trim().isNotEmpty)
          () => _SectionTitle(display.f_label, show: true),
        for (final store in display.store) () => _StoreRow(store),
      ],
    () => const _Deals(),
    if (state.allStores.isNotEmpty) ...[
      () => _SectionTitle('All stores in New York', spaceAbove: 26),
      for (final store in state.allStores) () => _StoreRow(store),
    ],
  ];
}

class _DashboardText extends StatelessWidget {
  const _DashboardText(this.s, {this.size = 14, this.weight = .w400, this.color = _ink, this.underline = false, this.lines});

  final String s;
  final double size;
  final FontWeight weight;
  final Color color;
  final bool underline;
  final int? lines;

  @override
  Widget build(BuildContext context) => Text(
    s,
    maxLines: lines,
    overflow: lines == null ? null : .ellipsis,
    style: TextStyle(
      fontFamily: 'InstacartSansBody',
      letterSpacing: 0,
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      color: color,
      decoration: underline ? .underline : .none,
    ),
  );

}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () {},
    child: child,
  );

}

class _DealLogo extends StatelessWidget {
  const _DealLogo();

  

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      'lib/page/dashboard/logos/wegmans.png',
      width: 44,
      height: 36,
      fit: .fill,
    ),
  );

}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader(this.topPadding);

  final double topPadding;

  @override
  Widget build(BuildContext context) => Container(
    height: 229.333,
    decoration: const BoxDecoration(
      color: Color(0xFFF7F6EF),
      border: Border(bottom: BorderSide(color: Color(0xFFD6D5D0), width: .7)),
    ),
    child: Column(
      children: [
        SizedBox(height: topPadding),
        SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _DashboardButton(
                  Row(
                    children: [
                      _DashboardText('Times Square', size: 16, weight: .w700),
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 10,
                        color: _ink,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _DashboardButton(
                  const Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 23,
                    color: _ink,
                  ),
                ),
                const SizedBox(width: 24),
                _DashboardButton(
                  SizedBox(
                    width: 28,
                    height: 32,
                    child: Stack(
                      clipBehavior: .none,
                      children: [
                        const Positioned(
                          top: 5,
                          child: Icon(
                            CupertinoIcons.cart,
                            size: 25,
                            color: _ink,
                          ),
                        ),
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            width: 17,
                            height: 17,
                            alignment: .center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF132B),
                              shape: .circle,
                              border: Border.all(color: CupertinoColors.white),
                            ),
                            child: _DashboardText(
                              '5',
                              size: 11,
                              color: CupertinoColors.white,
                              weight: .w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48,
            child: CupertinoTextField(
              placeholder: 'Search products, stores, and recipes',
              placeholderStyle: const TextStyle(
                fontFamily: 'InstacartSansBody',
                letterSpacing: 0,
                fontSize: 13,
                color: _ink,
              ),
              style: const TextStyle(
                fontFamily: 'InstacartSansBody',
                letterSpacing: 0,
                fontSize: 13,
                color: _ink,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.search, size: 22, color: _ink),
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFCDCED3)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            for (final c in [
              ('Grocery', 'grocery'),
              ('Restaurants', 'restaurant'),
              ('Alcohol', 'glass'),
              ('Express', 'snack'),
              ('Retail', 'gift'),
            ])
              _DashboardButton(
                Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: SvgPicture(
                        AssetBytesLoader('asset/${c.$2}.svg.vec'),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _DashboardText(c.$1, size: 13, weight: .w500),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );

}

class _DashboardFilters extends StatelessWidget {
  const _DashboardFilters();

  

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 65,
    child: SingleChildScrollView(
      scrollDirection: .horizontal,
      padding: const EdgeInsets.fromLTRB(16, 17, 0, 16),
      child: Row(
        children: [
          for (final (icon, label) in [
            (Icons.sell, 'Offers'),
            (Icons.storefront, 'Pickup'),
            (Icons.credit_card, 'EBT'),
            (Icons.attach_money, 'No markups'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _DashboardButton(
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9EC),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: _ink),
                      const SizedBox(width: 5),
                      _DashboardText(label, size: 13, weight: .w500),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

}

class _StoreGrid extends StatelessWidget {
  const _StoreGrid(this.stores, this.total) : super(key: const ValueKey('dashboard-store-grid'));

  final List<Store> stores;
  final int total;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 312,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            SizedBox(
              height: 103,
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  for (var col = 0; col < 4; col++)
                    Expanded(child: _StoreGridCell(stores, row * 4 + col, total)),
                ],
              ),
            ),
        ],
      ),
    ),
  );

}

class _StoreGridCell extends StatelessWidget {
  const _StoreGridCell(this.stores, this.index, this.total);

  final List<Store> stores;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isShowAll = index == 11;
    if (!isShowAll && index >= stores.length) return const SizedBox.shrink();
    final store = isShowAll ? null : stores[index];
    return _DashboardButton(
      Column(
        children: [
          SizedBox(
            height: 54,
            child: Align(
              alignment: .topCenter,
              child: isShowAll
                  ? Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF343638),
                        shape: .circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    )
                  : _StoreLogo(store: store!),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: isShowAll
                ? _DashboardText('Show all', size: 13, weight: .w500, lines: 1)
                : _StoreName(store!, size: 13, weight: .w500),
          ),
          const SizedBox(height: 1),
          isShowAll
              ? _DashboardText('$total stores', size: 12, color: _gray)
              : _StoreDelivery(store!, compact: true),
        ],
      ),
    );
  }

}

class _StoreName extends StatelessWidget {
  const _StoreName(this.store, {this.size = 16, this.weight = .w700});

  final Store store;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final name = store.name;
    return name == null || name.trim().isEmpty
        ? const SizedBox.shrink()
        : _DashboardText(name, size: size, weight: weight, lines: 1);
  }

}

class _StoreDelivery extends StatelessWidget {
  const _StoreDelivery(this.store, {this.compact = false});

  final Store store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final delivery = store.f_deliveryBy;
    if (delivery != null && delivery.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final noMarkups = delivery == null;
    final Color textColor;
    if (noMarkups) {
      textColor = _ink;
    } else if (compact) {
      textColor = const Color.fromRGBO(29, 39, 33, 1);
    } else {
      textColor = const Color(0xFF008A00);
    }
    return Container(
      color: noMarkups ? _yellow : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 0,
        vertical: compact ? 2 : 0,
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (!compact && !noMarkups)
            const Icon(Icons.bolt, size: 13, color: Color(0xFF008A00)),
          _DashboardText(
            noMarkups
                ? 'No markups'
                : '${compact ? 'By' : 'Delivery by'} ${_deliveryTime(delivery)}',
            size: compact ? 12 : 13,
            weight: compact || noMarkups ? .w400 : .w500,
            color: textColor,
          ),
        ],
      ),
    );
  }

}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.show = false, this.spaceAbove = 0});

  final String title;
  final bool show;
  final double spaceAbove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, spaceAbove, 16, 22),
    child: Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(child: _DashboardText(title, size: 20, weight: .w700)),
        if (show) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _DashboardButton(
              _DashboardText(
                'Show all',
                size: 13,
                weight: .w500,
                underline: true,
              ),
            ),
          ),
        ],
      ],
    ),
  );

}

class _StoreRow extends StatelessWidget {
  const _StoreRow(this.store);

  final Store store;

  @override
  Widget build(BuildContext context) {
    final tags = (store.f_tags ?? const <String>[])
        .where(
          (tag) =>
              tag.trim().isNotEmpty &&
              !(store.f_deliveryBy == null && tag == 'No markups'),
        )
        .toList();
    final metadata = <Widget>[
      if (store.f_deliveryBy == null || store.f_deliveryBy!.trim().isNotEmpty)
        _StoreDelivery(store),
      _DashboardText('${store.f_locationRange.toStringAsFixed(1)} mi', size: 13),
      if (store.f_priceRange?.trim().isNotEmpty ?? false)
        _DashboardText(store.f_priceRange!, size: 13),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _StoreLogo(store: store, width: 64, height: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                _StoreName(store),
                Wrap(
                  crossAxisAlignment: .center,
                  spacing: 3,
                  runSpacing: 2,
                  children: [
                    for (var i = 0; i < metadata.length; i++) ...[
                      if (i > 0) _DashboardText('·', size: 13),
                      metadata[i],
                    ],
                  ],
                ),
                if (tags.isEmpty)
                  const SizedBox.shrink()
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final tag in tags)
                          Container(
                            color: tag == 'No markups'
                                ? _yellow
                                : const Color(0xFFF5F5F5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            child: _DashboardText(tag, size: 13),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _Deals extends StatelessWidget {
  const _Deals();

  

  @override
  Widget build(BuildContext context) => Container(
    height: 384,
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: Color(0xFFECECEF)),
        bottom: BorderSide(color: Color(0xFFECECEF)),
      ),
    ),
    child: Column(
      children: [
        SizedBox(
          height: 77,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              crossAxisAlignment: .start,
              children: [
                _DealLogo(),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    _DashboardText('Deals for you', size: 20, weight: .w700),
                    _DashboardText(
                      'At Wegmans',
                      size: 13,
                      color: _gray,
                      weight: .w500,
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _DashboardButton(
                    _DashboardText(
                      'Show all',
                      size: 13,
                      weight: .w500,
                      underline: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 305,
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              crossAxisAlignment: .start,
              children: [
                _Product(false, false, 'https://www.instacart.com/image-server/394x394/filters:fill(FFFFFF,true):format(jpg)/d2lnr5mha7bycj.cloudfront.net/product-image/file/large_41a72720-3923-40b1-b4c9-bfd4ee7df429.jpeg'),
                _Product(true, false, 'https://www.instacart.com/image-server/394x394/filters:fill(FFFFFF,true):format(jpg)/d2lnr5mha7bycj.cloudfront.net/product-image/file/large_4e600ada-4cdb-4647-a10d-5480db5c712f.jpg'),
                _Product(false, true, 'https://www.instacart.com/image-server/394x394/filters:fill(FFFFFF,true):format(jpg)/d2lnr5mha7bycj.cloudfront.net/product-image/file/large_7abd49d5-8d5d-484c-8695-fc614e1071fd.jpg'),
              ],
            ),
          ),
        ),
      ],
    ),
  );

}

class _Product extends StatelessWidget {
  const _Product(this.ketchup, this.everything, this.image);

  final bool ketchup;
  final bool everything;
  final String image;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 137,
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            height: 128,
            child: Stack(
              clipBehavior: .none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: 125,
                  height: 125,
                  child: Image.network(
              image,
              fit: .contain,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
                ),
                Positioned(
                  right: 3,
                  top: 3,
                  child: _DashboardButton(
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF008C00),
                        shape: .circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: CupertinoColors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                if (ketchup)
                  Positioned(
                    left: 33,
                    bottom: 0,
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: _DashboardText('Gluten-free', size: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'InstacartSansBody',
                letterSpacing: 0,
                fontSize: 16,
                fontWeight: .w700,
                color: _ink,
              ),
              children: [
                const TextSpan(text: '\$'),
                TextSpan(text: ketchup ? '5' : '8'),
                WidgetSpan(
                  alignment: .top,
                  child: _DashboardText(
                    ketchup ? '59' : '09',
                    size: 11,
                    weight: .w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          _ProductTag(ketchup ? 'Spend \$24, save \$4' : 'With loyalty card'),
          if (!ketchup) ...[const SizedBox(height: 4), _ProductTag('Buy 2 for \$13')],
          const SizedBox(height: 1),
          _DashboardText(
            switch ((ketchup, everything)) {
              (true, _) => 'Heinz Tomato\nKetchup',
              (_, true) => 'Wegmans 6 Pack\nEverything Bagels',
              _ => 'Wegmans 6 Pack\nPlain Bagels',
            },
            size: 13,
            color: _gray,
          ),
          const SizedBox(height: 2),
          _DashboardText(ketchup ? '20 oz' : '21 oz', size: 13, color: _gray),
          const SizedBox(height: 5),
          _DashboardButton(
            Container(
              height: 24,
              width: 129,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _DashboardText(
                    'See eligible ite...',
                    size: 11,
                    weight: .w500,
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 11,
                    color: _ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

}

class _ProductTag extends StatelessWidget {
  const _ProductTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    color: _yellow,
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
    child: _DashboardText(label, size: 13, weight: .w500, lines: 1),
  );

}

String _deliveryTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return value;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  if (hour > 23 || minute > 59) return value;
  return '${hour % 12 == 0 ? 12 : hour % 12}:${match[2]}${hour < 12 ? 'am' : 'pm'}';
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.store, this.width = 68, this.height = 51});

  final Store store;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hex = store.backgroundColor.replaceFirst('#', '');
    final color = (hex.length == 6 || hex.length == 8)
        ? int.tryParse(hex, radix: 16)
        : null;
    final background = color == null
        ? CupertinoColors.white
        : Color(hex.length == 6 ? 0xFF000000 | color : color);
    final images = store.images;
    final image = images == null || images.isEmpty ? null : images.last;
    return Container(
      key: ValueKey('store-image-${store.id}'),
      width: width,
      height: height,
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDADADD)),
      ),
      child: image == null || image.trim().isEmpty
          ? const SizedBox.shrink()
          : Image.network(
              image,
              fit: .contain,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
    );
  }
}
