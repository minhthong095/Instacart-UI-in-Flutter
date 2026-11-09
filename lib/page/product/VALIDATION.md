# Product mapping validation

## Implementation and launch

- `ProductScreen` is the standalone preview mounted by the existing `lib/main.dart` `CupertinoApp`; no route parameters or navigation were added.
- Launched with `flutter run -d 00008120-0008053E3672201E -t lib/main.dart` on the connected iPhone (iOS 26.3.1, 393 × 852 logical viewport, DPR 3).
- `flutter analyze lib/page/product lib/main.dart` reported no product-screen issues. It reported three existing unused-import warnings in `lib/main.dart` (`mock_store_page.dart`, `aisle_detail_screen.dart`, `store_screen.dart`); those unrelated imports were left intact.
- `git diff --check` passed.

## Captured service selection

The captured state was selected through `MockProductService` using the exact discovered store/product identity:

- Store `5454`, product `items_27338-83200535` — **Member’s Mark Lactose Free 2% Reduced Fat Milk**, `$4.86`.
- `getProductDisplay` returned four groups, each with five products. The returned labels and counts are recorded below. First, middle, and last product examples are shown for each group; all identities are `(shopId, id)`.

| Group occurrence | Returned label | Count | First / middle / last examples `(shopId, id; name; price)` |
|---|---|---:|---|
| 0 | Choose snack selections | 5 | `(5454, items_27338-63773826; Member’s Mark Tiramisu Cake; $18.28)` / `(5454, items_27338-98169501; Chobani Vanilla Flavored Nonfat Greek Yogurt; $7.71)` / `(5454, items_27338-18016559; Member’s Mark Cookie Tray; $24.31)` |
| 1 | Discover dinner ideas | 5 | `(5454, items_27338-16603403; Sabrett Natural Casing Beef Frankfurters; $23.70)` / `(5454, items_27338-29217551; IQBAR Chocolate Variety Pack, High Protein, High Fiber, Low Sugar; $17.06)` / `(5454, items_27338-19047014; Orange On Vine Tomato; $6.06)` |
| 2 | Consider meal companions | 5 | `(5454, items_27338-70588629; Sargento Fun! Balanced Breaks® Variety Snack Kit, 8-Pack; $13.99)` / `(5454, items_27338-63978789; Ninja Luxe Café Premier Series 3-in-1 Espresso Machine; $669.78)` / `(5454, items_27338-92894481; Dark Chocolate Peanut Butter Cup Coconut Bite; $15.42)` |
| 3 | Discover everyday favorites | 5 | `(5454, items_27338-63773270; Member’s Mark Blueberry Bagels; $4.66)` / `(5454, items_27338-41258721; Dial Foaming Hand Wash, Antibacterial & Moisturizing, 7.5 Ounce, Pack of 4; $14.37)` / `(5454, items_27338-37040811; Ajinomoto Vegetable Fried Rice, Teppanyaki Style; $15.81)` |

## Full-page capture

- PNG: `.image-to-flutter-cache/product-01a1b169-fc09-7132-8607-e960f56a7275/product-full-page.png`
- Manifest: `.image-to-flutter-cache/product-01a1b169-fc09-7132-8607-e960f56a7275/capture-runs/flutter-1793979268599-stvQ6h/manifest.json`
- Screen/mode: `product` / eager; output 1179 × 7338 pixels, viewport 393 × 852 logical pixels at DPR 3.
- Manifest reports `complete: true`, `restored: true`, and original/restored scroll offset `0.0`.
- Opened and inspected the exported PNG. The hero uses the returned product image; product name, unit, price, stock label, and supplied information sections render. All four returned recommendation headings and card rails appear before the fixed quantity/add footer. No clipping or overflow is visible. Only part of each rail’s next card is visible at the horizontal viewport edge, consistent with the horizontal scrolling layout.
- Image fallback, unavailable/error states, and control interactions were not exercised in this capture-only validation.
