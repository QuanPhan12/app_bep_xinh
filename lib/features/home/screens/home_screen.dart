import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home.dart';
import 'views/home_mobile_view.dart';
import 'views/home_tablet_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(),
      child: const ResponsiveLayout(
        mobile: HomeMobileView(),
        tablet: HomeTabletView(),
      ),
    );
  }
}
