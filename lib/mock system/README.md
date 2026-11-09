# Local mock services (V3)

All six asynchronous interfaces and their entities are exported from
`mock_system.dart`. Controllers depend on interfaces. Share one repository:

```dart
final repository = MockDataRepository(seed: 42);
final DashboardService dashboard = MockDashboardService(repository: repository);
final StoreFilterByService filter = MockStoreFilterByService(repository: repository);
final StorePage page = MockStorePage(repository: repository);
final ProductService products = MockProductService(repository: repository);
final ShopByAisleService aisles = MockShopByAisleService(repository: repository);
final AisleDetailService details = MockAisleDetailService(repository: repository);

final categories = await page.getCategories('1175');
if (categories != null) {
  for (final category in categories) {
    for (var i = 0; i < category.items.length; i++) {
      final product = category.items[i];

    }
  }
}
```

`DashboardService`: `getStoreDisplayOnHeader()` samples 20 stores;
`getStoreDisplays()` returns seven labeled groups of five;
`getAllStores()` samples 100 stores.

`StoreFilterByService`: `getCarouselsAtHeader()` samples 11 entries across shops;
`getStoresDisplay()` returns five stores with their complete resolved catalogs;
`getAllStores()` separately samples 100 stores. No implicit filter state exists.

`StorePage`: `getCarousels(storeId)` returns the complete ordered carousel;
`getCategories(storeId)` returns the complete ordered flat category membership,
hydrated from that shop's products.

`ProductService`: `getProduct(storeId, productId)` resolves the exact composite
identity; `getProductDisplay(storeId, productId)` validates the anchor then samples
one through five sections with distinct labels. Each section contains up to five
unique same-store products, excluding the anchor. Tiny recommendation pools are
not padded. An anchor-only catalog returns `[]`.

`ShopByAisleService.getAisles(storeId)` returns hierarchy summaries without reading
products. `AisleDetailService.getAisleDetail(storeId, aisleId)` hydrates only the
selected aisle, preserving every sub-aisle, category and product occurrence.
Filtering the nested result belongs to the consuming application.

## Assets and source inventory

Initialize Flutter bindings before asset-backed calls. `lib/main.dart` runs the
debug demonstration outside widget builds, catches errors and starts the existing
UI. Profile/release builds skip the demonstration. Services never use network I/O
or machine-specific paths.

`pubspec.yaml` registers the actual runtime sources:

- `mock/stores.jsonl`
- `mock/store_carousels.jsonl`
- `mock/store_categories_products.jsonl`
- `mock/store_aisles+subs+categories_products.jsonl`
- `mock/product full data/products/` (explicit nested directory registration)

The product directory is about 1.1 GiB. Reference JSON, navigation category data,
old hierarchy JSON and backup files are not runtime collections. Each nonblank
JSONL line is independently parsed with physical line numbers.

`data_sources/dataset_inventory.dart` records verified source files. Update it
when dataset files change. A path absent from that inventory is known missing;
an inventoried path that cannot be read throws a loading error, including when
asset registration is broken. `InMemoryMockTextDataSource` supplies its own
inventory. Custom text loaders can implement `MockAssetInventory` or pass
`assetInventory` to the repository. The inventory fallback is the bundled set.
`StoreDataSource` injection remains supported for existing dashboard callers.

## Null, empty and error contracts

Every method returns a non-null Future whose result is nullable.

| Condition | Result |
| --- | --- |
| Blank arguments or unsafe shop path components | `ArgumentError` |
| Unknown well-formed shop, product or aisle | `null` plus an injectable diagnostic |
| Known shop with no associated carousel/category/hierarchy record | `null` |
| Required source absent from verified inventory | `null` and diagnostic |
| Valid present empty collection or sampling pool | immutable `[]` |
| Missing product file for a direct product/catalog-dependent method | `null` |
| Missing/ambiguous individual membership reference | one `null` product slot, parents retained |
| Malformed JSON, wrong required field types, failed inventoried reads | contextual `MockDataException` |
| Conflicting store, carousel or top-level membership/hierarchy identity | contextual `MockDataException` |
| Multiple occurrences of a requested aisle ID in one shop | `null` and ambiguity diagnostic |

Shop identifiers accept source `shopId` or `shopID`, trim boundary whitespace,
convert integers to strings and preserve string leading zeros. Conflicting aliases
fail. Safe identifiers use letters, digits, underscore or hyphen; unknown safe IDs
return null. `retailer_id` is separate metadata. Product and aisle IDs are matched
exactly, after rejecting blank arguments; product content is never normalized or
split. Product ownership comes exclusively from the validated store ID and exact
`<shopId>.jsonl` filename. Prefixes, slugs and retailer IDs never establish ownership.

## Hydration, diagnostics and source serialization

`StoreCategory.items` and `AisleSubCategory.itemIds` are immutable
`List<Proudct?>`. `sourceItemIds` retains the exact ID arrays in the same order,
including repeated occurrences. A null slot is unresolved. `resolutionIssues`
reports `missing_product_file`, `missing_product_id`,
`duplicate_identical_product` and `conflicting_product_records`, with shop,
requested ID, asset, physical line, full membership path and matching detail-row
locations when available. Pass `diagnosticSink: (issue) { ... }` to observe direct
lookup, missing association and duplicate diagnostics. Console output is not the
only way to inspect issues. The repository does not accumulate diagnostic history;
callers control retention in their sink. Membership diagnostics belong only to
the response in which they occur.

All product rows are indexed before duplicate policy is applied. Identical rows
resolve to one shared immutable entity with all row provenance. Conflicting rows
remain ambiguous: direct lookup is null; membership hydration preserves null
slots; recommendations report and exclude those identities. A complete catalog
request throws rather than returning a partial successful catalog. Identical
stores and carousels collapse in first-occurrence order with provenance; identical
shop-associated records also collapse. Conflicting copies throw. Nested category,
sub-aisle and membership occurrences are never deduplicated or merged by ID.

Entities expose deeply immutable known fields and unknown `extras`. Source
locations and ownership metadata are separate from raw JSON. `toSourceJson()`
returns detached, lossless source entry JSON, retaining absent-versus-null keys,
unknown fields, literal URL placeholders, original membership ID arrays, text,
prices, currency strings and misspellings. Parent source serialization recursively
restores original children. `toJson()` is the enriched service representation;
hydrated arrays contain product objects/nulls and product fake fields are included.
Store source serialization preserves original `shopId`, `background_color`, etc.;
its service representation uses the established public Store field names.

Public compatibility spellings `Proudct`, `proudcts`, `proudctSlug` and
`isLoyaltyProgramAvailbale` remain intentional. `StoreDisplay.store` is a list;
`StoreServiceDisplay.store` is a single store. Product images have `url` and
`templateUrl`, separate from store logo arrays, carousel image strings and nullable
hierarchy images. `variants` is a nullable string list; `pricePerUnit` uses the
deeply immutable JSON-compatible `JsonValue` because future non-null shapes remain
unspecified. Null titles and aisle images are never replaced with invented values.

## Caching, randomness and configuration

Each source has its own cached initialization Future, including failures. Products
load lazily per shop and reuse their in-flight immutable index. Dashboard calls
read only stores. Carousel methods do not read products. Flat categories never
require hierarchy data; aisle methods never require flat categories. Hydrated
responses are constructed per request and are not cached, avoiding unbounded
expanded hierarchy copies. Repeated membership references share product objects.
Create a new repository to retry after changing an underlying asset.

`MockConfig` centralizes counts, probability settings, label pools and tags.
Normal nonempty store/carousel samples first shuffle unique identities, then sample
with replacement if needed to reach the count. Source order is never mutated.
Every randomized method samples again; results may overlap or repeat. Empty pools
return `[]`. Recommendation sections instead use at most five distinct candidates.

Selection uses its own seeded random stream. Entity enrichment uses a documented
31-bit polynomial hash (see `mock_random.dart`) of JSON-encoded seed and identity,
then an independent Dart Random. Stores use store ID; products use `(shopId, id)`.
Lazy/concurrent initialization or product/source ordering cannot alter a given
identity's fake values. Equal seeds and sequential call sequences reproduce
responses within the same Dart runtime; Dart does not promise identical Random
sequences across runtime versions. Unseeded repositories choose a random seed.
Each service accepts optional nonnegative `latency`, default zero.

Store fake fields: equal choices of null/`$`/`$$`/`$$$`; 25% null delivery time,
otherwise zero-padded `HH:mm` independent of the clock; inclusive one-decimal
0.2–5.0 location number; 25% null tags, otherwise one through four unique allowed
tags. The location unit is unspecified. The standalone draft `delivery` field
remains undefined and is not implemented.

Product fake fields: 25% null purchase history, otherwise integer 100–500 inclusive;
equal boolean stock flag; 25% null food text, otherwise one of twenty unique labels
of at most two words. These are synthetic UI values, not nutritional, purchase or
inventory claims. Real tags and all source data stay separate from `f_` values.

There are seven unique dashboard headings, exactly 100 unique goods labels of at
most five characters, exactly 100 unique recommendation headings of at most five
words, and twenty food labels of at most two words. Labels do not imply actual
classification, personalization, ranking or purchase associations.

## Verified source issues and validation

The current inventory contains 108 stores, 108 carousel shop records, 105 flat
membership shop records, 105 hierarchy shop records and 108 product files. The
active hierarchy contains 2,395 aisle occurrences, including 115 explicitly null
images. Stores `15114`, `16637767` and `416293` lack flat-membership records.

Product files `3027.jsonl` and `95087.jsonl` contain conflicting duplicate
identities (first conflicting rows 2429 and 746). Source files remain unchanged.
Those identities stay unresolved; complete-catalog calls selecting those stores
throw. Memberships also contain missing product references; null slots and issue
metadata deliberately expose these source limitations. No source data was invented
to fill these gaps.

Validation commands:

```sh
dart format 'lib/mock system' lib/main.dart lib/page/dashboard/dashboard_bloc.dart
flutter analyze
flutter test 'lib/mock system/test' test
flutter build ios --simulator --debug --no-pub
```

Focused fixtures cover all twelve methods, null/empty/error policy, same-shop joins,
identical/conflicting duplicates, one-to-one hydration, nested source round trips,
immutability, seed stability, concurrent caches and independent loading boundaries.
Bundled checks target source mapping and selected stores/aisles without exhaustively
hydrating the entire hierarchy. Startup checks verify readable demonstration output,
all services and UI startup even when demo asset loading fails.
