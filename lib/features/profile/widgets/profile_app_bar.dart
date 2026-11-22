import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../../core/widgets/app_appearance_picker.dart';

/// Giữ thao tác cài đặt trên AppBar cả khi hồ sơ đang tải hoặc tải lỗi.
class ProfileAppBar extends StatelessWidget {
  final VoidCallback onSettings;

  const ProfileAppBar({super.key, required this.onSettings});

  @override
  Widget build(BuildContext context) => AppSliverAppBar.tab(
    title: 'Cá nhân',
    actions: [
      const AppAppearancePicker(compact: true),
      IconButton(
        tooltip: 'Cài đặt',
        onPressed: context.onAppTap(onSettings, actionName: 'profile_settings'),
        icon: const Icon(PhosphorIconsRegular.gearSix, size: 22),
      ),
      const SizedBox(width: 8),
    ],
  );
}
