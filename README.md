# Instacart UI in Flutter

Eight screens rebuilt from screenshots in one week, with a close visual match.

## Real data

I scraped Instacart data for **108 stores**, including **457,527 product records**.
The data is stored in [`mock/`](mock/) and used by local mock services.
Some display values are generated for the UI.

[See the dataset details](mock/dataset_connections_for_agents.md)

## Featured screens

Top previews and lower Flutter views are shown below.
Click an image to open the full screenshot.
Products and text may differ from the original screenshots.

## Dashboard

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/dashboard/dashboard.png"><img src="docs/images/portfolio/dashboard-original.png" alt="Dashboard original screenshot — top preview" width="280"></a></td>
    <td><a href="lib/page/dashboard/dashboard.implementation.png"><img src="docs/images/portfolio/dashboard-flutter.png" alt="Dashboard Flutter implementation — top preview" width="280"></a></td>
    <td><a href="lib/page/dashboard/dashboard.implementation.png"><img src="docs/images/portfolio/dashboard-flutter-lower.png" alt="Dashboard Flutter implementation — lower view" width="280"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/dashboard/dashboard_screen.dart)

## Product

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/product/product.png"><img src="docs/images/portfolio/product-original.png" alt="Product original screenshot — top preview" width="280"></a></td>
    <td><a href="lib/page/product/product.implementation.png"><img src="docs/images/portfolio/product-flutter.png" alt="Product Flutter implementation — top preview" width="280"></a></td>
    <td><a href="lib/page/product/product.implementation.png"><img src="docs/images/portfolio/product-flutter-lower.png" alt="Product Flutter implementation — lower view" width="280"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/product/product_screen.dart)

## Store Filter by Service

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/store_filter_by_service/shop_filter_by_service.png"><img src="docs/images/portfolio/store-filter-by-service-original.png" alt="Store Filter by Service original screenshot — top preview" width="280"></a></td>
    <td><a href="lib/page/store_filter_by_service/store_filter_by_service.implementation.png"><img src="docs/images/portfolio/store-filter-by-service-flutter.png" alt="Store Filter by Service Flutter implementation — top preview" width="280"></a></td>
    <td><a href="lib/page/store_filter_by_service/store_filter_by_service.implementation.png"><img src="docs/images/portfolio/store-filter-by-service-flutter-lower.png" alt="Store Filter by Service Flutter implementation — lower view" width="280"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/store_filter_by_service/store_filter_by_service_screen.dart)

## More screens — 5 comparisons

<details>
<summary>Show screenshots</summary>

### Store

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/store/store.png"><img src="docs/images/portfolio/store-original.png" alt="Store original screenshot — top preview" width="220"></a></td>
    <td><a href="lib/page/store/store.implementation.png"><img src="docs/images/portfolio/store-flutter.png" alt="Store Flutter implementation — top preview" width="220"></a></td>
    <td><a href="lib/page/store/store.implementation.png"><img src="docs/images/portfolio/store-flutter-lower.png" alt="Store Flutter implementation — lower view" width="220"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/store/store_screen.dart)

### Shop by Aisle

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/shop_by_aisle/shop_by_aisle.png"><img src="docs/images/portfolio/shop-by-aisle-original.png" alt="Shop by Aisle original screenshot — top preview" width="220"></a></td>
    <td><a href="lib/page/shop_by_aisle/shop_by_aisle.implementation.png"><img src="docs/images/portfolio/shop-by-aisle-flutter.png" alt="Shop by Aisle Flutter implementation — top preview" width="220"></a></td>
    <td><a href="lib/page/shop_by_aisle/shop_by_aisle.implementation.png"><img src="docs/images/portfolio/shop-by-aisle-flutter-lower.png" alt="Shop by Aisle Flutter implementation — lower view" width="220"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/shop_by_aisle/shop_by_aisle_screen.dart)

### Aisle Detail

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/aisle_detail/aisle-detail.png"><img src="docs/images/portfolio/aisle-detail-original.png" alt="Aisle Detail original screenshot — top preview" width="220"></a></td>
    <td><a href="lib/page/aisle_detail/aisle-detail.implementation.png"><img src="docs/images/portfolio/aisle-detail-flutter.png" alt="Aisle Detail Flutter implementation — top preview" width="220"></a></td>
    <td><a href="lib/page/aisle_detail/aisle-detail.implementation.png"><img src="docs/images/portfolio/aisle-detail-flutter-lower.png" alt="Aisle Detail Flutter implementation — lower view" width="220"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/aisle_detail/aisle_detail_screen.dart)

### Cart

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/cart/cart.png"><img src="docs/images/portfolio/cart-original.png" alt="Cart original screenshot — top preview" width="220"></a></td>
    <td><a href="lib/page/cart/cart.implementation.png"><img src="docs/images/portfolio/cart-flutter.png" alt="Cart Flutter implementation — top preview" width="220"></a></td>
    <td><a href="lib/page/cart/cart.implementation.png"><img src="docs/images/portfolio/cart-flutter-lower.png" alt="Cart Flutter implementation — lower view" width="220"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/cart/cart_screen.dart)

### Checkout

<table>
  <thead><tr><th>Original</th><th>Flutter</th><th>Flutter — lower view</th></tr></thead>
  <tbody><tr>
    <td><a href="lib/page/checkout/checkout.png"><img src="docs/images/portfolio/checkout-original.png" alt="Checkout original screenshot — top preview" width="220"></a></td>
    <td><a href="lib/page/checkout/checkout.implementation.png"><img src="docs/images/portfolio/checkout-flutter.png" alt="Checkout Flutter implementation — top preview" width="220"></a></td>
    <td><a href="lib/page/checkout/checkout.implementation.png"><img src="docs/images/portfolio/checkout-flutter-lower.png" alt="Checkout Flutter implementation — lower view" width="220"></a></td>
  </tr></tbody>
</table>

[View Flutter code](lib/page/checkout/checkout_screen.dart)

</details>

## Explore the code

Each folder in [`lib/page/`](lib/page/) holds a screen. The eight screens are
standalone and are not connected by navigation.
