import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../constants/filter_constants.dart';

class CategoryFilterWidget extends ConsumerWidget {
  const CategoryFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(productFiltersProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return DropdownButton<String>(
      value: filters.category,
      hint: const Text('Category'),
      onChanged: (value) {
        if (value != null) {
          ref.read(productFiltersProvider.notifier).updateCategory(value);
        }
      },
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('All Categories'),
        ),
        ...FilterConstants.categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category),
          );
        }).toList(),
      ],
    );
  }
} 