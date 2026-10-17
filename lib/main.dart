import 'package:app_bep_xinh/app.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình kiểm tra tập trung cho hệ thống onTap
  _setupTapInterceptors();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const AppBepXinh(),
    ),
  );
}

void _setupTapInterceptors() {
  // 1. Cấu hình kiểm tra đăng nhập tập trung
  AppTapHandler.instance.configureAuth(
    isAuthenticated: () {
      // TODO: Thay bằng kiểm tra state từ AuthBloc / Token trong SharedPreferences / SecureStorage
      // Mặc định trả về false để demo hành vi chặn
      return false;
    },
    onUnauthenticated: (context, config) {
      AppMessenger.showWarning(
        context,
        'Hành động "${config.actionName ?? 'này'}" yêu cầu đăng nhập!',
        title: 'Chưa đăng nhập',
      );
    },
  );

  // 2. Cấu hình ghi nhận Analytics / Logging tập trung
  AppTapHandler.instance.configureAnalytics(
    onTrack: (actionName, params) {
      // TODO: Gửi sự kiện sang FirebaseAnalytics.instance.logEvent(name: actionName, parameters: params)
      debugPrint(
        '🚀 [Analytics Tracked] Action: $actionName | Params: $params',
      );
    },
  );
}
