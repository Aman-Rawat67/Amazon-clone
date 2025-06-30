import 'package:flutter/material.dart';
import '../../constants/filter_constants.dart';

class SortFilterWidget extends StatelessWidget {
  final Function(SortOption) onSortChanged;
  final Function(double?, double?) onPriceRangeChanged;
  final Function(double?) onRatingChanged;
  final SortOption selectedSort;
  final RangeValues selectedPriceRange;
  final double selectedRating;

  const SortFilterWidget({
    super.key,
    required this.onSortChanged,
    required this.onPriceRangeChanged,
    required this.onRatingChanged,
    required this.selectedSort,
    required this.selectedPriceRange,
    required this.selectedRating,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Sort dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SortOption>(
              value: selectedSort,
              isDense: true,
              hint: const Text('Sort By'),
              icon: const Icon(Icons.sort, size: 16),
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (!isMobile) const SizedBox(width: 8),
        // Price range dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PriceRange>(
              value: _getCurrentPriceRange(),
              isDense: true,
              hint: const Text('Price Range'),
              icon: const Icon(Icons.attach_money, size: 16),
              onChanged: (PriceRange? range) {
                if (range != null) {
                  onPriceRangeChanged(range.min, range.max);
                }
              },
              items: FilterConstants.priceRanges.map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(
                    range.label,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (!isMobile) const SizedBox(width: 8),
        // Rating filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: selectedRating,
              isDense: true,
              hint: const Text('Rating'),
              icon: const Icon(Icons.star_border, size: 16),
              onChanged: (value) {
                onRatingChanged(value);
              },
              items: FilterConstants.ratingFilters.map((rating) {
                return DropdownMenuItem(
                  value: rating,
                  child: rating == 0
                      ? const Text('All Ratings', style: TextStyle(fontSize: 14))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${rating.toInt()}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const Text(
                              ' & up',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  PriceRange _getCurrentPriceRange() {
    try {
      return FilterConstants.priceRanges.firstWhere(
        (range) => range.min == selectedPriceRange.start && range.max == selectedPriceRange.end,
        orElse: () => FilterConstants.priceRanges.first,
      );
    } catch (e) {
      return FilterConstants.priceRanges.first;
    }
  }
}