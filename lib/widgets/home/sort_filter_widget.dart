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
            border: Border.all(
              color: selectedSort != SortOption.newest ? Colors.blue : Colors.grey.shade300,
              width: selectedSort != SortOption.newest ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SortOption>(
              value: selectedSort,
              isDense: true,
              hint: const Text('Sort By'),
              icon: Icon(
                Icons.sort,
                size: 16,
                color: selectedSort != SortOption.newest ? Colors.blue : null,
              ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedSort == option ? Colors.blue : null,
                      fontWeight: selectedSort == option ? FontWeight.bold : null,
                    ),
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
            border: Border.all(
              color: selectedPriceRange.start > 0 || selectedPriceRange.end < double.infinity
                  ? Colors.blue
                  : Colors.grey.shade300,
              width: selectedPriceRange.start > 0 || selectedPriceRange.end < double.infinity ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PriceRange>(
              value: _getCurrentPriceRange(),
              isDense: true,
              hint: const Text('Price Range'),
              icon: Icon(
                Icons.attach_money,
                size: 16,
                color: selectedPriceRange.start > 0 || selectedPriceRange.end < double.infinity
                    ? Colors.blue
                    : null,
              ),
              onChanged: (PriceRange? range) {
                if (range != null) {
                  onPriceRangeChanged(range.min, range.max);
                }
              },
              items: FilterConstants.priceRanges.map((range) {
                final isSelected = range == _getCurrentPriceRange();
                return DropdownMenuItem(
                  value: range,
                  child: Text(
                    range.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.blue : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
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
            border: Border.all(
              color: selectedRating > 0 ? Colors.blue : Colors.grey.shade300,
              width: selectedRating > 0 ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: selectedRating,
              isDense: true,
              hint: const Text('Rating'),
              icon: Icon(
                Icons.star_border,
                size: 16,
                color: selectedRating > 0 ? Colors.blue : null,
              ),
              onChanged: (value) {
                onRatingChanged(value);
              },
              items: FilterConstants.ratingFilters.map((rating) {
                final isSelected = rating == selectedRating;
                return DropdownMenuItem(
                  value: rating,
                  child: rating == 0
                      ? Text(
                          'All Ratings',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.blue : null,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${rating.toInt()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                            Icon(
                              Icons.star,
                              size: 14,
                              color: isSelected ? Colors.blue : Colors.amber,
                            ),
                            Text(
                              ' & up',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
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