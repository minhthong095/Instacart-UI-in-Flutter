abstract final class MockConfig {
  static const storeAsset = 'mock/stores.jsonl';
  static const carouselAsset = 'mock/store_carousels.jsonl';
  static const hierarchyAsset =
      'mock/store_aisles+subs+categories_products.jsonl';
  static const demoSeed = 42;
  static const recommendationLimit = 5;
  static const maxRecommendationGroups = 5;
  static const minPurchaseHistory = 100;
  static const maxPurchaseHistory = 500;
  static const categoryAsset = 'mock/store_categories_products.jsonl';
  // Verified on-disk directory; the earlier notes used "product data".
  static const productAssetDirectory = 'mock/product full data/products';
  static const headerCount = 20;
  static const allStoresCount = 100;
  static const carouselHeaderCount = 11;
  static const serviceDisplayCount = 5;
  static const storesPerDisplay = 5;
  static const nullableOneIn = 4;
  static const maxFakeTags = 4;
  static const minDistanceTenths = 2;
  static const maxDistanceTenths = 50;
  static const hoursPerDay = 24;
  static const minutesPerHour = 60;

  static const List<String?> priceRanges = [null, r'$', r'$$', r'$$$'];
  static const displayLabels = [
    'Popular stores near you',
    'Continue browsing',
    'Discover more stores',
    'Explore grocery stores',
    'Browse local favorites',
    'Find your next stop',
    'More stores to explore',
  ];

  /// Mock goods labels only, not source-backed classifications or filters.
  static const serviceLabels = [
    'Bread',
    'Milk',
    'Eggs',
    'Meat',
    'Fish',
    'Fruit',
    'Veg',
    'Dairy',
    'Deli',
    'Rice',
    'Pasta',
    'Soup',
    'Beans',
    'Nuts',
    'Seeds',
    'Oil',
    'Salt',
    'Sugar',
    'Flour',
    'Tea',
    'Brew',
    'Juice',
    'Soda',
    'Water',
    'Wine',
    'Beer',
    'Cider',
    'Cocoa',
    'Honey',
    'Jam',
    'Jelly',
    'Candy',
    'Gum',
    'Chips',
    'Salsa',
    'Dips',
    'Sauce',
    'Spice',
    'Herbs',
    'Oats',
    'Bran',
    'Toast',
    'Bagel',
    'Cake',
    'Pies',
    'Buns',
    'Wraps',
    'Rolls',
    'Tofu',
    'Soy',
    'Miso',
    'Nori',
    'Sushi',
    'Clams',
    'Crab',
    'Prawn',
    'Tuna',
    'Trout',
    'Cod',
    'Beef',
    'Pork',
    'Lamb',
    'Duck',
    'Bacon',
    'Ham',
    'Jerky',
    'Pizza',
    'Fries',
    'Ice',
    'Cream',
    'Kefir',
    'Curds',
    'Brie',
    'Feta',
    'Gouda',
    'Edam',
    'Ghee',
    'Lard',
    'Dates',
    'Figs',
    'Kiwi',
    'Pears',
    'Apple',
    'Peach',
    'Plums',
    'Melon',
    'Lime',
    'Lemon',
    'Grape',
    'Mango',
    'Guava',
    'Kale',
    'Chard',
    'Leeks',
    'Onion',
    'Peas',
    'Corn',
    'Beets',
    'Yams',
    'Okra',
  ];

  /// Synthetic recommendation headings; no purchase associations are implied.
  static final List<String> productDisplayLabels = List.unmodifiable([
    'Frequently bought together',
    'Often Bought With',
    'Items to add next',
    'Customers also considered',
    for (final action in [
      'Explore',
      'Discover',
      'Browse',
      'Try',
      'Consider',
      'Shop',
      'Find',
      'Enjoy',
      'Choose',
      'Add',
      'Meet',
      'Revisit',
    ])
      for (final collection in [
        'everyday favorites',
        'pantry picks',
        'meal companions',
        'snack selections',
        'fresh finds',
        'kitchen staples',
        'dinner ideas',
        'breakfast essentials',
      ])
        '$action $collection',
  ]);
  static const foodLabels = [
    'Gluten-free',
    'Trans fat-free',
    'Organic',
    'Non-GMO',
    'Zero calories',
    'In season',
    'Whole grain',
    'Plant based',
    'Dairy-free',
    'Vegan',
    'Vegetarian',
    'Low sodium',
    'No additives',
    'Freshly picked',
    'Locally grown',
    'High fiber',
    'Protein rich',
    'Unsweetened',
    'Sugar-free',
    'Farm fresh',
  ];
  static const allowedFakeTags = [
    'EBT',
    'Lots of deals',
    'Bulk pricing',
    'Fresh produce',
    'Bulk buys',
    'Organic selection',
    'Open late',
    'Store-brand savings',
    'Weekly coupons',
    'International foods',
    'Rewards program',
    'Pickup & delivery',
    'Fresh bakery & deli',
    'Halal/Kosher options',
    'Easy parking',
    'Self-checkout',
  ];
}
