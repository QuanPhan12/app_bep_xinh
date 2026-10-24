import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

import 'views/cart_mobile_view.dart';
import 'views/cart_tablet_view.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: CartMobileView(),
      tablet: CartTabletView(),
    );
  }
}
