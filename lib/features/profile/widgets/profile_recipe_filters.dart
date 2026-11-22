import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';

import 'package:app_bep_xinh/core/tap/tap_extension.dart';

import '../cubits/profile/profile_state.dart';

class ProfileRecipeFilters extends StatelessWidget {
  final ProfileRecipeFilter selected;
  final ValueChanged<ProfileRecipeFilter> onSelected;
  const ProfileRecipeFilters({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final filter in ProfileRecipeFilter.values)
        AppChoiceChip(
          label: switch (filter) {
            ProfileRecipeFilter.all => 'Tất cả',
            ProfileRecipeFilter.under30 => 'Dưới 30 phút',
            ProfileRecipeFilter.from30 => 'Từ 30 phút',
          },
          selected: selected == filter,
          onSelected: (_) => context
              .onAppTap(
                () => onSelected(filter),
                actionName: 'profile_filter_${filter.name}',
              )
              ?.call(),
        ),
    ],
  );
}
