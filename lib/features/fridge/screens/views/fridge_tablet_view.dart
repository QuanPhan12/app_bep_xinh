import 'package:flutter/material.dart';

import 'fridge_mobile_view.dart';

/// Giao diện Tủ lạnh thông minh (Tablet View)
class FridgeTabletView extends StatelessWidget {
  const FridgeTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    // Khung chung dùng AppLayout; nội dung tự chia cột theo chiều rộng thực tế.
    return const FridgeMobileView();
  }
}
