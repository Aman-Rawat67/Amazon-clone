/// Constants for filtering and sorting products
class FilterConstants {
  static const List<String> categories = [
    'Electronics',
    'Fashion',
    'Home & Kitchen',
    'Books',
    'Sports',
    'Beauty',
    'Toys',
    'Automotive',
    'Health',
    'Grocery',
  ];

  static const List<PriceRange> priceRanges = [
    PriceRange(min: 0, max: 500, label: 'Under ₹500'),
    PriceRange(min: 500, max: 1000, label: '₹500 - ₹1000'),
    PriceRange(min: 1000, max: 2000, label: '₹1000 - ₹2000'),
    PriceRange(min: 2000, max: 5000, label: '₹2000 - ₹5000'),
    PriceRange(min: 5000, max: 10000, label: '₹5000 - ₹10000'),
    PriceRange(min: 10000, max: double.infinity, label: 'Above ₹10000'),
  ];

  static const List<double> ratingFilters = [0, 3, 4];
}

/// Price range model for filtering
class PriceRange {
  final double min;
  final double max;
  final String label;

  const PriceRange({
    required this.min,
    required this.max,
    required this.label,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceRange &&
        other.min == min &&
        other.max == max &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(min, max, label);
}

/// Enum for sorting options
enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  newest,
  popularity;

  String get displayName {
    switch (this) {
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.popularity:
        return 'Popularity';
    }
  }
} 