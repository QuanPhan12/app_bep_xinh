import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';

/* Widget gốc khởi chạy ứng dụng Bếp Xinh */
class AppBepXinh extends StatelessWidget {
  const AppBepXinh({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // Tích hợp responsive_framework cho toàn bộ ứng dụng
        final responsiveChild = ResponsiveBreakpoints.builder(
          child: child ?? const SizedBox.shrink(),
          breakpoints: const [
            Breakpoint(start: 0, end: 599, name: MOBILE),
            Breakpoint(start: 600, end: 1024, name: TABLET),
            Breakpoint(start: 1025, end: 1920, name: DESKTOP),
            Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
        return responsiveChild;
      },
    );
  }
}
