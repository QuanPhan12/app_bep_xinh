import 'package:flutter/material.dart';

import 'fridge_mobile_view.dart';

/// Giao diện Tủ lạnh thông minh (Tablet View)
class FridgeTabletView extends StatelessWidget {
  const FridgeTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    // Trên Tablet kế thừa bố cục đã được ConstrainedBox của FridgeMobileView
    return const FridgeMobileView();
  }
}
