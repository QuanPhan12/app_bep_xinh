import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';

/* Widget gốc khởi chạy ứng dụng Bếp Xinh */
class AppBepXinh extends StatelessWidget {
  const AppBepXinh({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const Scaffold(
        body: Center(
          child: Text('Bếp Xinh'),
        ),
      ),
    );
  }
}
