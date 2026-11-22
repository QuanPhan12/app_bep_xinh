import 'package:flutter/material.dart';

import '../../../core/widgets/app_tabs.dart';
import '../cubits/profile/profile_state.dart';

class ProfileRecipeTabs extends StatelessWidget {
  final ProfileTab selected;
  final ValueChanged<ProfileTab> onSelected;
  const ProfileRecipeTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => AppTabs(
    labels: const ['Đã đăng', 'Đã lưu'],
    selectedIndex: selected.index,
    onSelected: (index) => onSelected(ProfileTab.values[index]),
  );
}
