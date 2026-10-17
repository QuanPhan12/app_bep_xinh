import 'dart:async';

import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tap_config.dart';

/// Interface cho các Interceptor (bộ lọc / kiểm tra) trước và sau khi thực thi onTap.
/// Mỗi loại kiểm tra (check mạng, check auth, chống spam, log analytics, rung,...)
/// sẽ là một Interceptor riêng biệt, dễ dàng mở rộng và bảo trì.
abstract class TapInterceptor {
  const TapInterceptor();

  /// Chạy trước khi gọi onTap. Trả về `true` để tiếp tục, `false` để chặn hành động.
  FutureOr<bool> beforeExecute(BuildContext context, TapConfig config) => true;

  /// Chạy sau khi onTap đã hoàn thành thành công.
  void afterExecute(BuildContext context, TapConfig config) {}

  /// Chạy khi onTap xảy ra lỗi (exception).
  void onError(
    BuildContext context,
    TapConfig config,
    Object error,
    StackTrace stackTrace,
  ) {}
}

/// 1. Interceptor chống spam / double-click (Throttling)
class ThrottleTapInterceptor extends TapInterceptor {
  final Map<String, int> _lastTapTimes = {};
  int _globalLastTapTime = 0;

  @override
  bool beforeExecute(BuildContext context, TapConfig config) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final throttleMs = config.throttleDuration.inMilliseconds;

    if (throttleMs <= 0) return true;

    // Nếu có actionName, kiểm tra throttle riêng theo action; nếu không, kiểm tra theo global
    final key = config.actionName;
    if (key != null) {
      final lastTime = _lastTapTimes[key] ?? 0;
      if (now - lastTime < throttleMs) {
        debugPrint(
          '⚠️ [AppTap] Bị chặn: "$key" đang bị spam (chờ ${throttleMs}ms).',
        );
        return false;
      }
      _lastTapTimes[key] = now;
    } else {
      if (now - _globalLastTapTime < throttleMs) {
        debugPrint(
          '⚠️ [AppTap] Bị chặn: Tap toàn cục bị spam (chờ ${throttleMs}ms).',
        );
        return false;
      }
      _globalLastTapTime = now;
    }

    return true;
  }
}

/// 2. Interceptor phản hồi rung nhẹ (Haptic Feedback)
class HapticTapInterceptor extends TapInterceptor {
  const HapticTapInterceptor();

  @override
  bool beforeExecute(BuildContext context, TapConfig config) {
    if (config.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    return true;
  }
}

/// 3. Interceptor kiểm tra kết nối mạng Internet
class NetworkTapInterceptor extends TapInterceptor {
  final Connectivity _connectivity;

  NetworkTapInterceptor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> beforeExecute(BuildContext context, TapConfig config) async {
    if (!config.requiresNetwork) return true;

    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any(
        (result) =>
            result != ConnectivityResult.none &&
            result != ConnectivityResult.bluetooth,
      );

      if (!hasConnection) {
        if (context.mounted) {
          AppMessenger.showError(
            context,
            'Không có kết nối mạng. Vui lòng kiểm tra lại Wifi/4G!',
            title: 'Mất kết nối Internet',
          );
        }
        debugPrint(
          '⚠️ [AppTap] Chặn tap: Yêu cầu kết nối mạng nhưng đang offline.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [AppTap] Lỗi khi kiểm tra kết nối: $e');
    }

    return true;
  }
}

/// 4. Interceptor kiểm tra xác thực / đăng nhập (Auth Guard)
class AuthTapInterceptor extends TapInterceptor {
  /// Callback kiểm tra người dùng đã đăng nhập chưa
  bool Function()? isAuthenticated;

  /// Callback xử lý khi người dùng chưa đăng nhập (mở dialog, chuyển màn hình login)
  void Function(BuildContext context, TapConfig config)? onUnauthenticated;

  AuthTapInterceptor({this.isAuthenticated, this.onUnauthenticated});

  @override
  bool beforeExecute(BuildContext context, TapConfig config) {
    if (!config.requiresAuth) return true;

    final isAuth = isAuthenticated?.call() ?? false;
    if (!isAuth) {
      debugPrint(
        '⚠️ [AppTap] Chặn tap: Hành động "${config.actionName ?? 'unknown'}" yêu cầu đăng nhập.',
      );
      if (context.mounted) {
        if (onUnauthenticated != null) {
          onUnauthenticated!(context, config);
        } else {
          // Thông báo mặc định nếu chưa cấu hình callback
          AppMessenger.showWarning(
            context,
            'Vui lòng đăng nhập để tiếp tục thực hiện!',
            title: 'Yêu cầu đăng nhập',
          );
        }
      }
      return false;
    }

    return true;
  }
}

/// 5. Interceptor kiểm tra điều kiện tùy biến (Custom Guard)
class CustomGuardTapInterceptor extends TapInterceptor {
  const CustomGuardTapInterceptor();

  @override
  FutureOr<bool> beforeExecute(BuildContext context, TapConfig config) async {
    if (config.customGuard == null) return true;
    final allow = await config.customGuard!(context);
    return allow;
  }
}

/// 6. Interceptor ghi nhận Tracking / Analytics / Logging
class AnalyticsTapInterceptor extends TapInterceptor {
  /// Callback tùy chỉnh để gửi sự kiện sang Firebase Analytics, Mixpanel, AppsFlyer,...
  void Function(String actionName, Map<String, dynamic>? params)? onTrack;

  AnalyticsTapInterceptor({this.onTrack});

  @override
  void afterExecute(BuildContext context, TapConfig config) {
    final action = config.actionName;
    if (action != null && action.isNotEmpty) {
      debugPrint(
        '📊 [AppTap:Log] Thực thi hành động: "$action" | Params: ${config.params}',
      );
      onTrack?.call(action, config.params);
    }
  }

  @override
  void onError(
    BuildContext context,
    TapConfig config,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '❌ [AppTap:Error] Lỗi khi xử lý action "${config.actionName}": $error',
    );
  }
}
