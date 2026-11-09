import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../mock system/entities/carousel.dart';
import '../../mock system/entities/proudct.dart';
import '../../mock system/entities/store_service_display.dart';
import '../../mock system/implementations/mock_store_filter_by_service.dart';
import '../capture_support/capture_host.dart';

const _ink = Color(0xFF242529);
const _muted = Color(0xFF72767B);
const _yellow = Color(0xFFFBE148);
const _green = Color(0xFF00A64F);

enum _DisplayPhase { loading, data, empty, unavailable, error }

class _DisplayState {
  const _DisplayState(this.phase, [this.displays = const []]);

  final _DisplayPhase phase;
  final List<StoreServiceDisplay> displays;

  factory _DisplayState.fromSnapshot(
    AsyncSnapshot<List<StoreServiceDisplay>?> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const _DisplayState(_DisplayPhase.loading);
    }
    if (snapshot.hasError) return const _DisplayState(_DisplayPhase.error);
    final displays = snapshot.data;
    if (displays == null) return const _DisplayState(_DisplayPhase.unavailable);
    if (displays.isEmpty) return const _DisplayState(_DisplayPhase.empty);
    return _DisplayState(_DisplayPhase.data, displays);
  }
}

/// Editable reproduction of StoreFilterByService.png; reference facts are static.
class StoreFilterByServiceScreen extends StatefulWidget {
  const StoreFilterByServiceScreen({super.key});

  @override
  State<StoreFilterByServiceScreen> createState() =>
      _StoreFilterByServiceScreenState();
}

class _StoreFilterByServiceScreenState
    extends State<StoreFilterByServiceScreen> {
  late final MockStoreFilterByService _service = MockStoreFilterByService();
  late final Future<List<Carousel>?> _carousels = _service
      .getCarouselsAtHeader();
  late final Future<List<StoreServiceDisplay>?> _displays = _service
      .getStoresDisplay();

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: DefaultTextStyle(
      style: _style(14),
      child: CaptureHost.eager(
        screenId: 'store_filter_by_service',
        backgroundColor: CupertinoColors.white,
        headerBuilder: (_) => _Header(),
        contentBuilder: (_) => FutureBuilder<List<Carousel>?>(
          future: _carousels,
          builder: (context, carouselSnapshot) =>
              FutureBuilder<List<StoreServiceDisplay>?>(
                future: _displays,
                builder: (context, displaySnapshot) => _Content(
                  carousels: carouselSnapshot.data ?? const <Carousel>[],
                  displayState: _DisplayState.fromSnapshot(displaySnapshot),
                ),
              ),
        ),
      ),
    ),
  );
}

TextStyle _style(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
  double height = 1.3,
}) => TextStyle(
  fontFamily: 'InstacartSansBody',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: 0,
);

TextStyle _detailStyle({bool emphasized = false}) => TextStyle(
  fontFamily: 'Instacart_Sans_Text',
  fontSize: 12,
  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
  color: emphasized ? _ink : _muted,
  height: 18.2 / 12,
  letterSpacing: 0,
);

class _Text extends StatelessWidget {
  const _Text(
    this.text, {
    this.size = 13,
    this.weight = FontWeight.w400,
    this.color = _ink,
    this.height = 1.3,
    this.underline = false,
  });
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final bool underline;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: _style(
      size,
      weight: weight,
      color: color,
      height: height,
    ).copyWith(decoration: underline ? .underline : .none),
  );
}

class _Button extends StatelessWidget {
  const _Button(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () {},
    child: child,
  );
}

class _Logo extends StatelessWidget {
  const _Logo(this.name, this.width, this.height);
  final String name;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Image.asset(
    'lib/page/store_filter_by_service/logos/$name.png',
    width: width,
    height: height,
    fit: .fill,
  );
}

class _Art extends StatelessWidget {
  const _Art(this.width, this.height, {this.radius = 0});
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 146,
    child: Stack(
      children: [
        Positioned(
          left: 23,
          top: 66,
          child: _Button(
            const Icon(CupertinoIcons.arrow_left, size: 23, color: _ink),
          ),
        ),
        Positioned(
          left: 56,
          top: 63,
          child: _Text('Express', size: 20, weight: FontWeight.w700),
        ),
        Positioned(
          left: 345,
          top: 64,
          child: _Button(
            const Icon(CupertinoIcons.cart, size: 27, color: _ink),
          ),
        ),
        Positioned(
          left: 360,
          top: 55,
          child: Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD4423B),
              shape: .circle,
              border: Border.all(color: CupertinoColors.white),
            ),
            child: _Text(
              '5',
              size: 11,
              color: CupertinoColors.white,
              height: 1,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 98,
          height: 48,
          child: CupertinoTextField(
            prefix: const Padding(
              padding: EdgeInsets.only(left: 13, right: 5),
              child: Icon(CupertinoIcons.search, size: 23, color: _ink),
            ),
            placeholder: 'Search products and stores',
            placeholderStyle: _style(14, weight: FontWeight.w500),
            style: _style(14),
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              border: Border.all(color: const Color(0xFFCACBD0)),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.carousels});

  final List<Carousel> carousels;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: .horizontal,
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Row(
      crossAxisAlignment: .start,
      children: [
        for (final carousel in carousels)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                _CarouselArt(carousel.image),
                const SizedBox(height: 4),
                Text(
                  carousel.name,
                  style: _style(
                    14,
                    color: _ink,
                    height: 1.3,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _CarouselArt extends StatelessWidget {
  const _CarouselArt(this.image);

  final String image;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68,
    height: 68,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image.trim().isEmpty
          ? const _Art(68, 68, radius: 8)
          : Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _Art(68, 68, radius: 8),
            ),
    ),
  );
}

class _Store extends StatelessWidget {
  const _Store(this.i);
  final int i;
  @override
  Widget build(BuildContext context) {
    const names = [
      'CVS®',
      '7-Eleven',
      'Target: Fas...',
      'Gourmet G...',
      'Walgreens',
      'Fairway Now',
      'Stop & Sho...',
      'Show all',
    ];
    const times = [
      'By 12:15pm',
      'By 12:15pm',
      'By 12:15pm',
      'By 12:15pm',
      'By 12:00pm',
      'By 12:15pm',
      'By 12:30pm',
      '48 stores',
    ];
    final Widget mark;
    switch (i) {
      case 0:
        mark = _Logo('cvs', 49, 14);
      case 1:
        mark = _Logo('seven', 29, 36);
      case 2:
        mark = _Logo('target', 38, 11);
      case 3:
        mark = _Logo('gourmet', 68, 51);
      case 4:
        mark = _Logo('walgreens', 39, 24);
      case 5:
        mark = _Logo('fairway', 68, 51);
      case 6:
        mark = _Logo('stop', 68, 51);
      default:
        mark = Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF343538),
            shape: .circle,
          ),
          child: const Icon(
            CupertinoIcons.arrow_right,
            size: 27,
            color: CupertinoColors.white,
          ),
        );
    }
    return SizedBox(
      width: 90,
      height: 89,
      child: Column(
        children: [
          _Button(
            Container(
              width: 68,
              height: 51,
              clipBehavior: .antiAlias,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                border: i == 7
                    ? null
                    : Border.all(color: const Color(0xFFDBDCE0), width: .8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: mark),
            ),
          ),
          const SizedBox(height: 4),
          _Text(names[i], size: 14, weight: FontWeight.w500),
          const SizedBox(height: 1),
          _Text(times[i], size: 11, color: const Color(0xFF505256)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.display});

  final StoreServiceDisplay display;

  @override
  Widget build(BuildContext context) {
    final storeName = _nonblank(display.store.name) ?? 'Store';
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 4,
            child: Container(
              width: 48,
              height: 36,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _storeColor(display.store.backgroundColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _RemoteImage(
                url: _firstUsable(display.store.images ?? const []),
                width: 48,
                height: 36,
                fallback: const Icon(
                  CupertinoIcons.bag,
                  color: _muted,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            left: 72,
            top: -3,
            child: _Text(
              _nonblank(display.f_label) ?? 'Featured products',
              size: 21,
              weight: FontWeight.w700,
            ),
          ),
          Positioned(
            left: 72,
            top: 25,
            child: _Text(
              'At $storeName',
              size: 14,
              color: const Color(0xFF55585D),
            ),
          ),
          Positioned(
            right: 16,
            top: 14,
            child: _Button(_Text('View All', size: 14, underline: true)),
          ),
        ],
      ),
    );
  }
}

class _Plus extends StatelessWidget {
  const _Plus();

  @override
  Widget build(BuildContext context) => _Button(
    Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF3D8828),
        shape: .circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.plus,
        size: 26,
        color: CupertinoColors.white,
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(this.product);

  final Proudct product;

  @override
  Widget build(BuildContext context) {
    final image = _firstUsable(product.images.map((item) => item.url));
    final offer = _nonblank(product.offerLabelString);
    final price = _nonblank(product.price);
    final fullPrice = _nonblank(product.fullPrice);
    final unit = _nonblank(product.pricingUnit);
    final freeText = _nonblank(product.f_freeText);

    return SizedBox(
      width: 111,
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 111,
            height: 104,
            child: _RemoteImage(
              url: image,
              width: 111,
              height: 104,
              fit: BoxFit.contain,
              fallback: const Icon(
                CupertinoIcons.photo,
                color: Color(0xFFB8BBC0),
                size: 25,
              ),
            ),
          ),
          Positioned(right: 4, top: 0, child: _Plus()),
          Positioned(
            left: 0,
            top: 108,
            width: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    color: offer == null ? null : _yellow,
                    padding: offer == null
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      price ?? 'Price unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(18, weight: FontWeight.w700),
                    ),
                  ),
                ),
                if (fullPrice != null && fullPrice != price) ...[
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      fullPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(
                        11,
                        color: _muted,
                      ).copyWith(decoration: TextDecoration.lineThrough),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (offer != null)
            Positioned(
              left: 0,
              top: 137,
              width: 111,
              height: 38,
              child: Container(
                color: _yellow,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  offer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _style(12, weight: FontWeight.w500),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: offer == null ? 142 : 179,
            width: 111,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _detailStyle(),
                ),
                if (unit != null)
                  Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _detailStyle(),
                  ),
                if (freeText != null)
                  Text(
                    freeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _detailStyle(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({required this.display});

  final StoreServiceDisplay display;

  @override
  Widget build(BuildContext context) {
    if (display.proudcts.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: _DisplayMessage('No products available')),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: display.proudcts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _ProductCard(display.proudcts[index]),
      ),
    );
  }
}

class _StoreServiceSection extends StatelessWidget {
  const _StoreServiceSection({required this.display, required this.isLast});

  final StoreServiceDisplay display;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [
      _SectionHeading(display: display),
      const SizedBox(height: 27),
      _ProductRail(display: display),
      const SizedBox(height: 17),
      const _Line(),
      SizedBox(height: isLast ? 24 : 19),
    ],
  );
  }
}

class _DisplayMessage extends StatelessWidget {
  const _DisplayMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: _style(13, color: _muted),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: const Color(0xFFF0F0F2));
}

class _RemoteImage extends StatelessWidget {
  const _RemoteImage({
    required this.url,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final String? url;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _nonblank(url);
    if (imageUrl == null) {
      return SizedBox(width: width, height: height, child: fallback);
    }
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: width, height: height, child: fallback),
    );
  }
}

String? _nonblank(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value.trim();
}

String? _firstUsable(Iterable<String> urls) {
  for (final value in urls) {
    final url = value.trim();
    final uri = Uri.tryParse(url);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !url.contains('{width=') &&
        !url.contains('{height=}')) {
      return url;
    }
  }
  return null;
}

Color _storeColor(String value) {
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null || hex.length != 8) return const Color(0xFFF3F3F4);
  return Color(parsed);
}

class _Content extends StatelessWidget {
  const _Content({required this.carousels, required this.displayState});

  final List<Carousel> carousels;
  final _DisplayState displayState;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 345,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 12,
              height: 96,
              child: _Categories(carousels: carousels),
            ),
            Positioned(left: 0, right: 0, top: 113, child: _Line()),
            for (var i = 0; i < 8; i++)
              Positioned(
                left: 15 + (i % 4) * 90,
                top: 138 + (i ~/ 4) * 99,
                child: _Store(i),
              ),
            Positioned(left: 0, right: 0, top: 344, child: _Line()),
          ],
        ),
      ),
      const SizedBox(height: 19),
      switch (displayState.phase) {
        _DisplayPhase.loading => const _DisplayMessage(
          'Loading store sections…',
        ),
        _DisplayPhase.unavailable => const _DisplayMessage(
          'Store sections are unavailable',
        ),
        _DisplayPhase.error => const _DisplayMessage(
          'Could not load store sections',
        ),
        _DisplayPhase.empty => const _DisplayMessage(
          'No store sections available',
        ),
        _DisplayPhase.data => Column(
          children: [
            for (var i = 0; i < displayState.displays.length; i++)
              _StoreServiceSection(
                display: displayState.displays[i],
                isLast: i == displayState.displays.length - 1,
              ),
          ],
        ),
      },
    ],
  );
}
