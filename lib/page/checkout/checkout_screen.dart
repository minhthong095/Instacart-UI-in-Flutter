import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

import '../capture_support/capture_host.dart';

const _ink = Color(0xFF252629);
const _muted = Color(0xFF727378);
const _line = Color(0xFFE9E9EC);
const _green = Color(0xFF3D8825);

/// Editable, static reproduction of Checkout.png.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: CaptureHost.eager(
      screenId: 'checkout',
      backgroundColor: CupertinoColors.white,
      headerBuilder: (context) => const _Header(),
      contentBuilder: (context) => const _Content(),
      footerBuilder: (context) => const _Footer(),
    ),
  );

}

TextStyle get _legalStyle => const TextStyle(
    fontFamily: 'InstacartSansBody',
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0,
    color: _muted,
  );

class _Text extends StatelessWidget {
  const _Text(this.value, {this.size = 13, this.weight = FontWeight.w400, this.color = _ink, this.height = 1.2, this.underline = false});

  final String value;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final bool underline;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      fontFamily: '.SF Pro Text',
      fontSize: size,
      letterSpacing: size <= 11 ? 0 : null,
      height: height,
      fontWeight: weight,
      color: color,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
    ),
  );
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1, child: ColoredBox(color: _line));
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => const Icon(CupertinoIcons.chevron_right, size: 17, color: _ink);
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => _Text(title, size: 22, weight: FontWeight.w700);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF7F5F0),
    child: Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top),
        SizedBox(
          height: 54,
          child: Stack(
            children: [
              Positioned(
                left: 16,
                top: 14,
                child: _Button(
                  'Back',
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      shape: .circle,
                      border: Border.all(color: _line),
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_left,
                      size: 23,
                      color: _ink,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB3336),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: _Text(
                    'Target',
                    size: 8,
                    weight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) => Column(
    children: [_Delivery(), _Options(), _Summary(), _Payments(), _Legal()],
  );
}

class _Delivery extends StatelessWidget {
  const _Delivery();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 127,
    child: Stack(
      children: [
        Positioned(left: 16, top: 31, child: _Heading('Deliver to')),
        Positioned(
          left: 16,
          top: 75,
          child: _Text(
            'Times Square, New York, NY',
            size: 18,
            weight: FontWeight.w700,
          ),
        ),
        Positioned(
          left: 16,
          top: 94,
          child: _Text('Leave at the door · Add instructions', color: _muted),
        ),
        Positioned(
          right: 16,
          top: 86,
          child: _Button('Delivery address', _Chevron()),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _Divider()),
      ],
    ),
  );
}

class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
          child: Container(
            height: 59,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              border: Border.all(color: _ink),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _Option(
              Icons.bolt,
              'Priority',
              '15-54 min',
              r'$7.99',
              oldPrice: r'$9.99',
            ),
          ),
        ),
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: _Option(
              Icons.delivery_dining,
              'Fast',
              '11:33am–1:03pm',
              r'$7.99',
            ),
          ),
        ),
        SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: _Option(
              Icons.calendar_month,
              'Schedule and save',
              'As soon as 2pm today',
              r'$0',
              down: true,
            ),
          ),
        ),
        _Divider(),
      ],
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option(this.icon, this.title, this.subtitle, this.price, {this.oldPrice, this.down = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String? oldPrice;
  final bool down;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Icon(icon, size: 25, color: _ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  _Text(title, weight: FontWeight.w600, size: 15,),
                  if (down) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 12,
                      color: _ink,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              _Text(subtitle, color: _muted),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: .center,
          children: [
            Row(
              children: [
                if (oldPrice case final oldPrice?) ...[
                  Text(
                    oldPrice,
                    style: const TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 13,
                      color: _muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 3),
                ],
                _Text(price, weight: FontWeight.w600),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 397,
    child: Stack(
      children: [
        Positioned(left: 16, top: 15, child: _Heading('Summary')),
        Positioned(left: 16, top: 50, child: _Text('Delivery Tip')),
        Positioned(
          left: 16,
          top: 63,
          width: 295,
          child: _Text(
            'Tips are optional. 100% of your tip goes to the\ndelivery person.',
            color: _muted,
            height: 1.05,
          ),
        ),
        Positioned(right: 16, top: 69, child: _Text(r'$0.00')),
        Positioned(
          left: 16,
          right: 12,
          top: 109,
          height: 32,
          child: Row(
            children: [
              for (final label in [r'$0', r'$1', r'$2', r'$4', 'Other']) ...[
                if (label != r'$0') const SizedBox(width: 4),
                Expanded(
                  child: _Button(
                    label,
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: label == r'$0' ? _ink : const Color(0xFFE8E8EA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _Text(
                        label,
                        weight: FontWeight.w600,
                        color: label == r'$0' ? CupertinoColors.white : _ink,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(left: 16, right: 16, top: 148, child: _Divider()),
        Positioned(
          left: 16,
          right: 16,
          top: 153,
          child: Column(
            children: [
              _Cost('3 items', r'$35.54', boldValue: true),
              _Cost('Delivery fee', r'$7.99'),
              _Cost('Service fee', r'$3.49', info: true),
              _Cost('Priority fee', r'$0.00', info: true),
              _Cost('Regulatory response fee', r'$5.99', info: true),
            ],
          ),
        ),
        Positioned(left: 16, right: 16, top: 290, child: _Divider()),
        Positioned(
          left: 16,
          right: 16,
          top: 291,
          child: SizedBox(
            height: 41,
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                _Text('Total', size: 15, weight: FontWeight.w700),
                _Text(r'$53.01', size: 15, weight: FontWeight.w700),
              ],
            ),
          ),
        ),
        Positioned(left: 16, right: 16, top: 332, child: _Divider()),
        Positioned(
          left: 16,
          right: 16,
          top: 333,
          height: 63,
          child: _Button(
            'Offers and promo codes',
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                _Text('Offers and promo codes', weight: FontWeight.w500),
                _Chevron(),
              ],
            ),
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _Divider()),
      ],
    ),
  );
}

class _Cost extends StatelessWidget {
  const _Cost(this.label, this.value, {this.info = false, this.boldValue = false});

  final String label;
  final String value;
  final bool info;
  final bool boldValue;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 26,
    child: Row(
      children: [
        _Text(label),
        if (info) ...[
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.info, size: 15, color: _ink),
        ],
        const Spacer(),
        _Text(value, weight: boldValue ? FontWeight.w700 : FontWeight.w400),
      ],
    ),
  );
}

class _Paypal extends StatelessWidget {
  const _Paypal({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 36 : 24,
    height: compact ? 10 : 16,
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(2),
    ),
    alignment: Alignment.center,
    child: Row(
      mainAxisSize: .min,
      children: [
        _Text(
          'P',
          size: compact ? 7 : 5,
          weight: FontWeight.w900,
          color: const Color(0xFF003087),
        ),
        _Text(
          ' Pay Later',
          size: compact ? 4 : 3.1,
          weight: FontWeight.w600,
          color: const Color(0xFF20345A),
        ),
      ],
    ),
  );
}

class _Payments extends StatelessWidget {
  const _Payments();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 199,
    child: Stack(
      children: [
        Positioned(left: 16, top: 16, child: _Heading('Pay with')),
        Positioned(
          right: 16,
          top: 14,
          child: _Button(
            'Edit payment',
            _Text('Edit', weight: FontWeight.w600, underline: true),
          ),
        ),
        Positioned(
          left: 16,
          right: 0,
          top: 47,
          height: 92,
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Row(
              children: [
                _PaymentCard(
                  111,
                  selected: true,
                  children: [
                    _Paypal(),
                    const SizedBox(height: 9),
                    _Text(
                      'PayPal Pay Later',
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                    _Text('Default', size: 11),
                  ],
                ),
                const SizedBox(width: 8),
                _PaymentCard(
                  110,
                  children: [
                    Container(
                      width: 24,
                      height: 17,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDADADD)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisAlignment: .center,
                        children: [
                          const Icon(
                            Icons.apple,
                            size: 9,
                            color: CupertinoColors.black,
                          ),
                          _Text('Pay', size: 6, weight: FontWeight.w600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    _Text('Apple Pay', size: 11, weight: FontWeight.w600),
                  ],
                ),
                const SizedBox(width: 8),
                _PaymentCard(
                  158,
                  children: [
                    const Icon(CupertinoIcons.plus, size: 23, color: _ink),
                    const SizedBox(height: 4),
                    _Text(
                      'Add a payment method',
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Network('VISA', const Color(0xFF173B80)),
                        _Network('●●', const Color(0xFFEB5724)),
                        _Network('AMEX', const Color(0xFF3276BE)),
                        _Network('DISCOVER', _ink),
                        _Network('PayPal', const Color(0xFF003087)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 143,
          height: 60,
          child: _Button(
            'Make it a gift',
            Row(
              children: [
                const Icon(CupertinoIcons.gift_fill, size: 25, color: _ink),
                const SizedBox(width: 10),
                _Text('Make it a gift', weight: FontWeight.w600),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.info_circle_fill,
                  size: 13,
                  color: _ink,
                ),
                const Spacer(),
                _Chevron(),
              ],
            ),
          ),
        ),
        Positioned(left: 16, right: 16, bottom: 0, child: _Divider()),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard(this.width, {this.selected = false, required this.children});

  final double width;
  final bool selected;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 92,
    padding: const EdgeInsets.fromLTRB(10, 10, 7, 8),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFF7F7F8) : CupertinoColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? _ink : _line,
        width: selected ? 2 : 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: .start,
      children: children,
    ),
  );
}

class _Network extends StatelessWidget {
  const _Network(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 10,
    margin: const EdgeInsets.only(right: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(1),
    ),
    child: _Text(
      label,
      size: label.length > 4 ? 2*2 : 3.5*2,
      color: color,
      weight: FontWeight.w700,
    ),
  );
}

class _Legal extends StatelessWidget {
  const _Legal();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 305,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            "You accept full responsibility for the order once it's delivered. Items that do not require ID or delivery confirmation may be left at your door if requested or if you are not present when the order arrives.",
            style: _legalStyle,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: _legalStyle,
              children: [
                const TextSpan(
                  text: r'Your credit/debit card will be authorized for up to $60.97. Amounts will be finalized after order completion. If the order total exceeds your balance, your secondary payment method will be charged the difference. ',
                ),
                TextSpan(
                  text: 'Learn more.',
                  style: _legalStyle.copyWith(
                    color: _green,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(
                  text: " Instacart may charge retailers a fee in connection with orders placed using Instacart's services.",
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A bag fee may be added to your final total if required by law or the retailer. The fee will be visible on your receipt after delivery.',
            style: _legalStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'If items sell out, Instacart may check another location and split this order. Your tip will be prorated.',
            style: _legalStyle,
          ),
          const SizedBox(height: 12),
          Text('Prices may vary from those in store.', style: _legalStyle),
          const SizedBox(height: 12),
          Text(
            'New York law requires the following disclosure because we use personal information (such as delivery address) to calculate fees and offer certain personalized incentives: this price was set by an algorithm using your personal data.',
            style: _legalStyle,
          ),
        ],
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: CupertinoColors.white,
      border: Border(top: BorderSide(color: Color(0xFFD3D3D6))),
    ),
    padding: EdgeInsets.fromLTRB(
      16,
      0,
      16,
      MediaQuery.paddingOf(context).bottom,
    ),
    child: SizedBox(
      height: 152,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 13,
            child: Row(
              children: [
                _Text('Pay with', size: 17, weight: FontWeight.w700),
                const Spacer(),
                _Text('PayPal Pay Later', size: 15, weight: FontWeight.w600),
                const SizedBox(width: 12),
                _Paypal(compact: true),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 49,
            child: Text.rich(
              TextSpan(
                style: _legalStyle.copyWith(color: _ink),
                children: [
                  const TextSpan(
                    text: 'By clicking the button below, you agree to the ',
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            height: 56,
            child: _Button(
              'Continue',
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _Text(
                  'Continue',
                  size: 20,
                  weight: FontWeight.w700,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

