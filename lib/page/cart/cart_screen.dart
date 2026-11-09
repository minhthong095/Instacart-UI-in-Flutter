import 'package:flutter/cupertino.dart';

import '../capture_support/capture_host.dart';

const _ink = Color(0xFF252629);
const _muted = Color(0xFF626569);
const _green = Color(0xFF3D8825);

/// Editable, static reproduction of the supplied cart reference.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'cart',
      backgroundColor: CupertinoColors.white,
      headerBuilder: (_) => _Header(context),
      contentBuilder: (_) => _Content(),
      footerBuilder: (_) => _Footer(context),
    ),
  );
}

class _Text extends StatelessWidget {
  const _Text(this.value, {this.size = 13, this.weight = .w500, this.color = _ink, this.underline = false});
  final String value;
  final double size;
  final FontWeight weight;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      fontFamily: '.SF Pro Text',
      fontSize: size,
      height: 1.32,
      fontWeight: weight,
      color: color,
      decoration: underline ? .underline : null,
    ),
  );
}

class _Icon extends StatelessWidget {
  const _Icon(this.icon, {this.size = 20, this.color = _ink});
  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () {},
    child: Semantics(label: label, button: true, child: child),
  );
}

class _Photo extends StatelessWidget {
  const _Photo(this.width, this.height, this.url);
  final double width;
  final double height;
  final String? url;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Image.network(
              url ?? '',
              fit: .contain,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
  );
}

class _Line extends StatelessWidget {
  const _Line();


  @override
  Widget build(BuildContext context) => SizedBox(height: .7, child: ColoredBox(color: const Color(0xFFE5E5E5)));
}

class _Header extends StatelessWidget {
  const _Header(this.sourceContext);
  final BuildContext sourceContext;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(height: MediaQuery.paddingOf(sourceContext).top),
      SizedBox(
        height: 54,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: _Button(
                'Back',
                _Icon(CupertinoIcons.arrow_left, size: 23),
              ),
            ),
            const SizedBox(width: 40),
            Image.asset('lib/page/cart/target_logo.png', width: 53, height: 53),
            const SizedBox(width: 11),
            Image.asset(
              'lib/page/cart/wegmans_logo.png',
              width: 53,
              height: 53,
            ),
            const SizedBox(width: 12),
            _Button(
              'All 5 carts',
              SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: .center,
                  children: [
                    _Icon(CupertinoIcons.cart_fill, size: 26),
                    _Text('All 5 carts', size: 11),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 52,
              child: _Button(
                'Invite someone',
                _Icon(CupertinoIcons.person_badge_plus_fill, size: 22),
              ),
            ),
          ],
        ),
      ),
      _Line(),
    ],
  );
}

class _Content extends StatelessWidget {
  const _Content();


  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 17),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _Text('Target'),
            Row(
              children: [
                _Icon(CupertinoIcons.bolt_fill, size: 16, color: _green),
                _Text('Delivery by 11:30am', color: _green),
              ],
            ),
          ],
        ),
      ),
      _Item(
        'Smartfood Fiber Pop\nPopcorn Toffee And Sea...',
        r'$15.96',
        4,
        100,
        100,

    'https://www.instacart.com/image-server/394x394/filters:fill(FFFFFF,true):format(jpg)/d2lnr5mha7bycj.cloudfront.net/product-image/file/large_6a0f7f6e-32a4-4c4c-af6f-95cd261fa641.jpeg',
        137,
        offer: true,
      ),
      _Item(
        'Post Cocoa Pebbles\nBreakfast Cereal, Gluten...',
        r'$6.99',
        1,
         100,
        100,
        'https://www.instacart.com/assets/domains/product-image/file/large_b3dc8ef9-64d7-41e1-9f38-96e7337d0bd9.jpg',
        110,
      ),
      _Item(
        'GoMacro Oatmeal\nChocolate Chip Mini Mac...',
        r'$12.59',
        1,
            100,
        100,'https://www.instacart.com/image-server/600x/www.instacart.com/assets/domains/product-image/file/large_6393c46c-a9ff-4ad0-b603-97606cd0bd33.png',
        109,
      ),
      _Line(),
      SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              _Text('Item Subtotal', size: 16, weight: .w700),
              _Text(r'$35.54', size: 16, weight: .w700),
            ],
          ),
        ),
      ),
      _Line(),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 17, 12, 0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _Text('Complete your cart', size: 20, weight: .w700),
            _Text('Based on items in your cart', weight: .w400),
          ],
        ),
      ),
      _Recommendations(),
    ],
  );
}

class _Item extends StatelessWidget {
  const _Item(this.title, this.price, this.quantity, this.width, this.height, this.url, this.rowHeight, {this.offer = false});
  final String title;
  final String price;
  final int quantity;
  final double width;
  final double height;
  final String url;
  final double rowHeight;
  final bool offer;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: rowHeight,
    child: Stack(
      children: [
        Positioned(
          left: 16,
          top: offer ? 34 : 21,
          width: 59,
          height: 60,
          child: Center(child: _Photo(width, height, url)),
        ),
        Positioned(
          left: 88,
          top: 0,
          right: 140,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              _Text(title,weight: .w700),
              _Text(price),
              const SizedBox(height: 3),
              Row(
                children: [
                  _Icon(
                    CupertinoIcons.arrow_2_squarepath,
                    size: 10,
                    color: _muted,
                  ),
                  const SizedBox(width: 5),
                  _Text('Replace with best match', size: 11, color: _muted),
                ],
              ),
              if (offer)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: _Button(
                    'Save 0.75 dollars',
                    Row(
                      children: [
                        _Icon(CupertinoIcons.square, size: 18),
                        const SizedBox(width: 4),
                        ColoredBox(
                          color: const Color(0xFFFFE347),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _Text(r'Save $0.75'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 9),
              _Button(
                'Edit instructions',
                Row(
                  children: [
                    _Icon(CupertinoIcons.pencil, size: 12, color: _muted),
                    const SizedBox(width: 5),
                    _Text(
                      'Edit instructions',
                      size: 11,
                      color: _muted,
                      underline: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          top: offer ? 32 : 17,
          child: Container(
            width: 110,
            height: 34,
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: .spaceEvenly,
              children: [
                _Button(
                  quantity == 4 ? 'Decrease quantity' : 'Remove item',
                  _Icon(
                    quantity == 4
                        ? CupertinoIcons.minus
                        : CupertinoIcons.trash_fill,
                    size: 17,
                  ),
                ),
                _Text('$quantity ct'),
                _Button(
                  'Increase quantity',
                  _Icon(CupertinoIcons.plus, size: 21),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Recommendations extends StatelessWidget {
  const _Recommendations();


  @override
  Widget build(BuildContext context) => SizedBox(
    height: 346,
    child: ListView.separated(
      scrollDirection: .horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: 2,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (_, i) => SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            SizedBox(
              height: 196,
              child: Stack(
                children: [
                  Positioned.fill( child: _Photo(70, 70, i == 0 ? 'https://www.instacart.com/image-server/394x394/filters:fill(FFFFFF,true):format(jpg)/d2lnr5mha7bycj.cloudfront.net/product-image/file/large_f8606e41-4e64-41c1-a3da-8cb247d3d84d.png': 'https://www.instacart.com/image-server/600x/www.instacart.com/assets/domains/product-image/file/large_3da0558f-685c-4bf4-9591-ec2f4020fc5d.png')),
                  Positioned(
                    right: 0,
                    top: 22,
                    child: _Button(
                      'Add recommended item',
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: .circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _Icon(
                          CupertinoIcons.plus,
                          size: 27,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: _ink,
                  fontWeight: .w700,
                ),
                children: [
                  WidgetSpan(
                    alignment: .top,
                    child: Text(
                      r'$',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: .w700,
                        color: _ink,
                      ),
                    ),
                  ),
                  TextSpan(text: '22', style: TextStyle(fontSize: 20)),
                  WidgetSpan(
                    alignment: .top,
                    child: Text(
                      '99',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: .w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            _Text(
              i == 0
                  ? 'Chomps Sea Salt Beef'
                  : 'Chomps Grass-Fed\nJalapeno Beef',
              color: _muted,
              weight: .w400,
            ),
            Row(
              children: [
                for (var j = 0; j < 5; j++)
                  _Icon(
                    CupertinoIcons.star_fill,
                    size: 16,
                    color: const Color(0xFFF8BE42),
                  ),
                _Text(
                  i == 0 ? ' (798)' : ' (1.31K)',
                  color: _muted,
                  weight: .w400,
                ),
              ],
            ),
            _Text(
              i == 0 ? '8 ct' : '8 x 1.15 oz',
              color: _muted,
              weight: .w400,
            ),
            Row(
              children: [
                _Icon(
                  CupertinoIcons.line_horizontal_3_decrease,
                  size: 15,
                  color: const Color(0xFF2F701C),
                ),
                const SizedBox(width: 3),
                _Text('Many in stock'),
              ],
            ),
            _Text('Sponsored', color: _muted, weight: .w400),
          ],
        ),
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer(this.sourceContext);
  final BuildContext sourceContext;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Line(),
      Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(sourceContext).bottom + 12,
        ),
        child: _Button(
          'Go to checkout',
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                const SizedBox(width: 106),
                Expanded(
                  child: _Text(
                    'Go to checkout',
                    size: 20,
                    weight: .w700,
                    color: CupertinoColors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F701C),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: _Text(
                    r'$35.54',
                    color: const Color(0xFFE0EBD9),
                    weight: .w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
