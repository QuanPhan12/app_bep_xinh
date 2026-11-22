import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/ai_message.dart';
import 'ai_chat_repository.dart';

String resolveAiApiBaseUrl({
  required bool debugWeb,
  required String host,
  String configured = '',
}) {
  if (configured.isNotEmpty) return configured;
  // Web debug cùng máy phải dùng proxy local; Auth/Firestore vẫn là dữ liệu thật.
  // Không áp dụng cho hosting/release hoặc thiết bị, nơi localhost là máy khác.
  if (debugWeb && const ['localhost', '127.0.0.1', '::1'].contains(host)) {
    return 'http://127.0.0.1:5001/bepxinh-b0be7/asia-southeast1/bepXinhAi';
  }
  return 'https://asia-southeast1-bepxinh-b0be7.cloudfunctions.net/bepXinhAi';
}

class HttpAiChatRepository implements AiChatRepository {
  final http.Client client;
  final FirebaseAuth auth;
  final AuthService session;
  final String baseUrl;
  HttpAiChatRepository({
    required this.client,
    required this.auth,
    required this.session,
    String? baseUrl,
  }) : baseUrl =
           baseUrl ??
           resolveAiApiBaseUrl(
             debugWeb: kDebugMode && kIsWeb,
             host: Uri.base.host,
             configured: const String.fromEnvironment('AI_API_BASE_URL'),
           );
  Future<Map<String, dynamic>> _request(
    String path, [
    Map<String, String>? body,
  ]) async {
    final uid = session.userId, user = auth.currentUser;
    if (uid == null || user?.uid != uid) {
      throw const AiChatFailure('Vui lòng đăng nhập lại để sử dụng AI.');
    }
    try {
      final token = await user!.getIdToken();
      if (token == null || token.isEmpty) {
        throw const AiChatFailure('Phiên đăng nhập đã hết hạn.');
      }
      if (session.userId != uid || auth.currentUser?.uid != uid) {
        throw const AiChatFailure('Phiên đăng nhập đã thay đổi.');
      }
      final url = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/$path');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final response =
          await (body == null
                  ? client.get(url, headers: headers)
                  : client.post(url, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 40));
      if (session.userId != uid || auth.currentUser?.uid != uid) {
        throw const AiChatFailure('Phiên đăng nhập đã thay đổi.');
      }
      if (response.bodyBytes.length > 2000000) {
        throw const FormatException('AI response too large');
      }
      if (response.statusCode == 404) {
        throw const AiChatFailure(
          'Trợ lý AI chưa được kích hoạt trên máy chủ. Vui lòng quay lại sau.',
        );
      }
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final message = (result['error'] as Map?)?['message'];
        throw AiChatFailure(
          message is String && message.length <= 300
              ? message
              : 'Chưa kết nối được AI. Vui lòng thử lại.',
        );
      }
      return result;
    } on AiChatFailure {
      rethrow;
    } on TimeoutException {
      throw const AiChatFailure(
        'AI phản hồi lâu hơn dự kiến. Thử gửi lại để kiểm tra kết quả.',
      );
    } catch (_) {
      throw const AiChatFailure(
        'Chưa kết nối được AI. Kiểm tra mạng và thử lại.',
      );
    }
  }

  @override
  Future<List<AiMessage>> history() async {
    final result = await _request('history'), messages = result['messages'];
    if (messages is! List || messages.length > 40) {
      throw const FormatException('Invalid AI history');
    }
    return List.unmodifiable(
      messages.map(
        (m) => AiMessage.fromJson(Map<String, dynamic>.from(m as Map)),
      ),
    );
  }

  @override
  Future<List<AiMessage>> send(String message, String requestId) async {
    final result = await _request('chat', {
      'message': message,
      'requestId': requestId,
    });
    return [
      AiMessage.fromJson(Map<String, dynamic>.from(result['user'] as Map)),
      AiMessage.fromJson(Map<String, dynamic>.from(result['assistant'] as Map)),
    ];
  }
}
