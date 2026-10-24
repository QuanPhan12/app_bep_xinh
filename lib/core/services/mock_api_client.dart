import 'dart:convert';

import 'package:flutter/services.dart';

/// Mô phỏng độ trễ và JSON response; chỉ dùng ở tầng service.
class MockApiClient {
  final AssetBundle bundle;
  final Duration latency;

  MockApiClient({
    AssetBundle? bundle,
    this.latency = const Duration(milliseconds: 450),
  }) : bundle = bundle ?? rootBundle {
    if (latency.isNegative) throw ArgumentError.value(latency, 'latency');
  }

  Future<Map<String, dynamic>> get(String resource) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final response = await bundle.loadString('assets/mock/$resource.json');
    final decoded = jsonDecode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object');
    }
    return decoded;
  }

  Future<void> simulateRequest() =>
      latency == Duration.zero ? Future.value() : Future<void>.delayed(latency);

  Future<void> simulateWrite() => simulateRequest();
}
