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

  /// Chạy khi tiến trình onTap kết thúc (luôn được gọi trong finally hoặc khi chuỗi bị hủy/chặn).
  void onComplete(TapConfig config) {}
}

/// 1. Interceptor chống spam / double-click (Throttling) & Chống tap trùng đồng thời (Multi-Touch / Concurrency Guard)
class ThrottleTapInterceptor extends TapInterceptor {
  final Map<String, int> _lastTapTimes = {};
  int _globalLastTapTime = 0;
  bool _isExecuting = false;
  String? _currentRunningAction;

  /// Khoảng thời gian tối thiểu giữa 2 lần chạm bất kỳ trên toàn bộ ứng dụng (chống user dùng 2 ngón tay nhấn 2 nút cùng lúc)
  final Duration defaultGlobalThrottleDuration;

  ThrottleTapInterceptor({
    this.defaultGlobalThrottleDuration = const Duration(milliseconds: 100),
  });

  /// Kiểm tra xem hiện tại có đang trong tiến trình xử lý một action nào không
  bool get isExecuting => _isExecuting;

  /// Đặt lại toàn bộ trạng thái khóa
  void reset() {
    _lastTapTimes.clear();
    _globalLastTapTime = 0;
    _isExecuting = false;
    _currentRunningAction = null;
  }

  @override
  bool beforeExecute(BuildContext context, TapConfig config) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. CHỐNG NHẤN 2 NÚT CÙNG LÚC / ĐA CHẠM (Multi-touch Simultaneous Tap Guard)
    // Nếu không cho phép multi-tap, bất kỳ 2 lần chạm nào trên toàn app phải cách nhau tối thiểu globalInterval
    if (!config.allowMultiTap) {
      final globalIntervalMs =
          (config.globalThrottleDuration ?? defaultGlobalThrottleDuration)
              .inMilliseconds;
      if (globalIntervalMs > 0 && now - _globalLastTapTime < globalIntervalMs) {
        debugPrint(
          '⚠️ [AppTap] Bị chặn: Nhấn cùng lúc 2 nút / đa chạm quá nhanh '
          '(cách nhau ${now - _globalLastTapTime}ms < ${globalIntervalMs}ms). '
          'Bỏ qua action "${config.actionName ?? 'unnamed'}".',
        );
        return false;
      }
    }

    // 2. CHỐNG CHẠY ĐÈ KHI ĐANG CÓ ACTION KHÁC XỬ LÝ (Concurrency Lock)
    // Chặn người dùng nhấn các nút khác trong khi một tác vụ bất đồng bộ đang chạy
    if (!config.allowConcurrent && _isExecuting) {
      debugPrint(
        '⚠️ [AppTap] Bị chặn: Đang có hành động "$_currentRunningAction" đang xử lý, '
        'chặn hành động "${config.actionName ?? 'unnamed'}".',
      );
      return false;
    }

    // 3. CHỐNG SPAM TRÊN CÙNG MỘT NÚT (Per-action Throttling)
    final throttleMs = config.throttleDuration.inMilliseconds;
    final key = config.actionName;
    if (key != null && throttleMs > 0) {
      final lastTime = _lastTapTimes[key] ?? 0;
      if (now - lastTime < throttleMs) {
        debugPrint(
          '⚠️ [AppTap] Bị chặn: "$key" đang bị spam (chờ ${throttleMs}ms).',
        );
        return false;
      }
      _lastTapTimes[key] = now;
    }

    // Cập nhật mốc thời gian toàn cục và kích hoạt cờ đang thực thi
    _globalLastTapTime = now;
    _isExecuting = true;
    _currentRunningAction = config.actionName ?? 'unnamed';

    return true;
  }

  @override
  void onComplete(TapConfig config) {
    // Luôn giải phóng cờ đang thực thi khi action hoàn thành (dù thành công, lỗi hay bị chặn)
    _isExecuting = false;
    _currentRunningAction = null;
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
