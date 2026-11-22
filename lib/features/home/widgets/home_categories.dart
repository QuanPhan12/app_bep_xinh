import 'package:flutter/material.dart';

import '../models/home_category.dart';

class HomeCategories extends StatelessWidget {
  final List<HomeCategory> categories;
  final ValueChanged<String>? onSelectCategory;
  const HomeCategories({
    super.key,
    required this.categories,
    this.onSelectCategory,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: category.id == 'cat_all',
              showCheckmark: false,
              key: ValueKey('home_category_${category.id}'),
              label: Text(category.title),
              onSelected: onSelectCategory == null
                  ? null
                  : (_) => onSelectCategory!(category.id),
            ),
          ),
      ],
    ),
  );
}
