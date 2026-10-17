import 'dart:async';
import 'package:flutter/material.dart';
import 'tap_config.dart';
import 'tap_interceptor.dart';

/// Điểm tập trung xử lý duy nhất (Single Point of Entry) cho mọi tương tác onTap trong ứng dụng.
/// Mọi click nút, card, banner, item,... đều đi qua đây để:
/// 1. Chống double-click/spam (Throttle)
/// 2. Phản hồi rung nhẹ (Haptic)
/// 3. Kiểm tra mạng nếu cần (Network Check)
/// 4. Kiểm tra quyền/đăng nhập nếu cần (Auth Guard)
/// 5. Kiểm tra điều kiện tùy biến (Custom Guard)
/// 6. Bắt lỗi không làm sập ứng dụng (Safe Execution)
/// 7. Ghi nhận log & Analytics (Tracking)
class AppTapHandler {
  AppTapHandler._() {
    _initDefaultInterceptors();
  }

  static final AppTapHandler instance = AppTapHandler._();

  final List<TapInterceptor> _interceptors = [];

  late final ThrottleTapInterceptor _throttleInterceptor;
  late final HapticTapInterceptor _hapticInterceptor;
  late final NetworkTapInterceptor _networkInterceptor;
  late final AuthTapInterceptor _authInterceptor;
  late final CustomGuardTapInterceptor _customGuardInterceptor;
  late final AnalyticsTapInterceptor _analyticsInterceptor;

  void _initDefaultInterceptors() {
    _throttleInterceptor = ThrottleTapInterceptor();
    _hapticInterceptor = const HapticTapInterceptor();
    _networkInterceptor = NetworkTapInterceptor();
    _authInterceptor = AuthTapInterceptor();
    _customGuardInterceptor = const CustomGuardTapInterceptor();
    _analyticsInterceptor = AnalyticsTapInterceptor();

    // Thứ tự chạy các interceptor:
    // 1. Chống spam trước
    // 2. Rung nhẹ phản hồi
    // 3. Kiểm tra mạng
    // 4. Kiểm tra auth
    // 5. Kiểm tra custom logic
    // 6. Analytics/Log
    _interceptors.addAll([
      _throttleInterceptor,
      _hapticInterceptor,
      _networkInterceptor,
      _authInterceptor,
      _customGuardInterceptor,
      _analyticsInterceptor,
    ]);
  }

  /// Cấu hình logic xác thực đăng nhập toàn cục
  void configureAuth({
    required bool Function() isAuthenticated,
    required void Function(BuildContext context, TapConfig config) onUnauthenticated,
  }) {
    _authInterceptor.isAuthenticated = isAuthenticated;
    _authInterceptor.onUnauthenticated = onUnauthenticated;
  }

  /// Cấu hình tracking / analytics toàn cục (Firebase, Mixpanel,...)
  void configureAnalytics({
    required void Function(String actionName, Map<String, dynamic>? params) onTrack,
  }) {
    _analyticsInterceptor.onTrack = onTrack;
  }

  /// Thêm một interceptor tùy biến vào chuỗi xử lý
  void addInterceptor(TapInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Kiểm tra xem ứng dụng có đang bận xử lý một hành động tap bất đồng bộ hay không
  static bool get isBusy => instance._throttleInterceptor.isExecuting;

  /// Đặt lại trạng thái khóa thực thi toàn cục
  static void resetLock() => instance._throttleInterceptor.reset();

  /// Hàm cốt lõi xử lý mọi hành động onTap
  static Future<void> handle(
    BuildContext context, {
    required FutureOr<void> Function()? onTap,
    TapConfig? config,
    String? actionName,
    bool requiresAuth = false,
    bool requiresNetwork = false,
    Duration throttleDuration = const Duration(milliseconds: 500),
    bool enableHaptic = true,
    Map<String, dynamic>? params,
    FutureOr<bool> Function(BuildContext context)? customGuard,
    bool allowConcurrent = false,
    bool allowMultiTap = false,
    Duration? globalThrottleDuration,
  }) async {
    if (onTap == null) return;

    final resolvedConfig = config ??
        TapConfig(
          actionName: actionName,
          requiresAuth: requiresAuth,
          requiresNetwork: requiresNetwork,
          throttleDuration: throttleDuration,
          enableHaptic: enableHaptic,
          params: params,
          customGuard: customGuard,
          allowConcurrent: allowConcurrent,
          allowMultiTap: allowMultiTap,
          globalThrottleDuration: globalThrottleDuration,
        );

    final interceptors = instance._interceptors;

    // 1. Chạy qua chuỗi beforeExecute của từng Interceptor
    for (final interceptor in interceptors) {
      if (!context.mounted) {
        _notifyComplete(interceptors, resolvedConfig);
        return;
      }
      final canContinue =
          await interceptor.beforeExecute(context, resolvedConfig);
      if (!canContinue) {
        // Bị chặn bởi một Interceptor (vd: mất mạng, chưa đăng nhập, spam, ấn 2 nút cùng lúc)
        _notifyComplete(interceptors, resolvedConfig);
        return;
      }
    }

    // 2. Thực thi hàm onTap chính một cách an toàn (try-catch-finally)
    try {
      final result = onTap();
      if (result is Future) {
        // Nếu sau khi gọi onTap mà màn hình hiện tại không còn active
        // (ví dụ: đã điều hướng sang màn hình mới qua context.push/pushNamed),
        // thì không được giữ khóa làm chặn các tương tác trên màn hình mới!
        final route = context.mounted ? ModalRoute.of(context) : null;
        if (route != null && !route.isCurrent) {
          _notifyComplete(interceptors, resolvedConfig);
          return;
        }

        await result;
      }

      if (context.mounted) {
        // 3. Gọi afterExecute khi thành công
        for (final interceptor in interceptors) {
          interceptor.afterExecute(context, resolvedConfig);
        }
      }
    } catch (error, stackTrace) {
      if (context.mounted) {
        // 4. Báo lỗi cho các interceptor khi có Exception
        for (final interceptor in interceptors) {
          interceptor.onError(context, resolvedConfig, error, stackTrace);
        }
      }
    } finally {
      // 5. Luôn gọi onComplete để giải phóng cờ đang thực thi (Concurrency Lock)
      _notifyComplete(interceptors, resolvedConfig);
    }
  }

  static void _notifyComplete(
    List<TapInterceptor> interceptors,
    TapConfig config,
  ) {
    for (final interceptor in interceptors) {
      interceptor.onComplete(config);
    }
  }

  /// Đóng gói `onTap` thành một `VoidCallback?` tương thích hoàn toàn với các widget của Flutter
  /// như `ElevatedButton(onPressed: AppTapHandler.wrap(context, ...))`
  /// Nếu `onTap` là null thì trả về `null` để nút chuyển sang trạng thái disabled.
  static VoidCallback? wrap(
    BuildContext context, {
    required FutureOr<void> Function()? onTap,
    TapConfig? config,
    String? actionName,
    bool requiresAuth = false,
    bool requiresNetwork = false,
    Duration throttleDuration = const Duration(milliseconds: 500),
    bool enableHaptic = true,
    Map<String, dynamic>? params,
    FutureOr<bool> Function(BuildContext context)? customGuard,
    bool allowConcurrent = false,
    bool allowMultiTap = false,
    Duration? globalThrottleDuration,
  }) {
    if (onTap == null) return null;

    return () {
      handle(
        context,
        onTap: onTap,
        config: config,
        actionName: actionName,
        requiresAuth: requiresAuth,
        requiresNetwork: requiresNetwork,
        throttleDuration: throttleDuration,
        enableHaptic: enableHaptic,
        params: params,
        customGuard: customGuard,
        allowConcurrent: allowConcurrent,
        allowMultiTap: allowMultiTap,
        globalThrottleDuration: globalThrottleDuration,
      );
    };
  }
}
