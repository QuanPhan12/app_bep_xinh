import 'dart:async';
import 'package:flutter/material.dart';

/// Cấu hình và metadata cho mỗi hành động onTap trong toàn ứng dụng.
class TapConfig {
  /// Tên hoặc mã định danh của hành động (dùng cho analytics, tracking, debounce riêng biệt)
  /// Ví dụ: 'login_submit', 'add_to_cart', 'btn_back'
  final String? actionName;

  /// Có yêu cầu người dùng phải đăng nhập trước khi thực hiện không?
  /// Nếu true và chưa login -> AuthTapInterceptor sẽ chặn lại và điều hướng/thông báo.
  final bool requiresAuth;

  /// Có yêu cầu kết nối mạng Internet trước khi thực hiện không?
  /// Nếu true và mất mạng -> NetworkTapInterceptor sẽ chặn lại và thông báo.
  final bool requiresNetwork;

  /// Thời gian tối thiểu giữa 2 lần tap để chống spam / double click (mặc định 500ms)
  final Duration throttleDuration;

  /// Có kích hoạt rung nhẹ (haptic feedback) khi chạm không? (mặc định true)
  final bool enableHaptic;

  /// Dữ liệu bổ sung đính kèm cho tracking / analytics
  final Map<String, dynamic>? params;

  /// Hàm kiểm tra điều kiện tùy biến trước khi thực thi. Trả về false sẽ chặn tap.
  final FutureOr<bool> Function(BuildContext context)? customGuard;

  const TapConfig({
    this.actionName,
    this.requiresAuth = false,
    this.requiresNetwork = false,
    this.throttleDuration = const Duration(milliseconds: 500),
    this.enableHaptic = true,
    this.params,
    this.customGuard,
  });

  /// Tạo bản sao với các thuộc tính được cập nhật
  TapConfig copyWith({
    String? actionName,
    bool? requiresAuth,
    bool? requiresNetwork,
    Duration? throttleDuration,
    bool? enableHaptic,
    Map<String, dynamic>? params,
    FutureOr<bool> Function(BuildContext context)? customGuard,
  }) {
    return TapConfig(
      actionName: actionName ?? this.actionName,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      requiresNetwork: requiresNetwork ?? this.requiresNetwork,
      throttleDuration: throttleDuration ?? this.throttleDuration,
      enableHaptic: enableHaptic ?? this.enableHaptic,
      params: params ?? this.params,
      customGuard: customGuard ?? this.customGuard,
    );
  }
}
