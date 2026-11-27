import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/ai_message.dart';

class AiModelConfig {
  final String key, model;
  final Uri endpoint;
  final bool gemini;
  final int dailyLimit;
  const AiModelConfig({
    required this.key,
    required this.model,
    required this.endpoint,
    required this.gemini,
    required this.dailyLimit,
  });
  factory AiModelConfig.fromJson(Map<String, dynamic> json) {
    final key = json['apiKey'] as String? ?? '';
    if (json['enabled'] != true || key.isEmpty) {
      throw const AiChatFailure('Trợ lý AI chưa khả dụng.');
    }
    final model = json['model'] as String? ?? '';
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,99}$').hasMatch(model)) {
      throw const AiChatFailure('Model chưa được cấu hình đúng.');
    }
    final gemini = json['provider'] == 'gemini',
        endpoint = Uri.parse(json['endpoint'] as String);
    if (endpoint.scheme != 'https' ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        (gemini && endpoint.host != 'generativelanguage.googleapis.com')) {
      throw const AiChatFailure('Địa chỉ API không hợp lệ.');
    }
    return AiModelConfig(
      key: key,
      model: model,
      endpoint: endpoint,
      gemini: gemini,
      dailyLimit: (json['dailyLimit'] as num? ?? 40).toInt().clamp(1, 100),
    );
  }
}

/// Chat và dinh dưỡng dùng cùng cấu hình runtime, không tự chọn model/key dự phòng.
class AiModelClient {
  final http.Client client;
  final FirebaseAuth auth;
  final AuthService session;
  final Future<Map<String, dynamic>> Function() loadConfig;
  const AiModelClient({
    required this.client,
    required this.auth,
    required this.session,
    required this.loadConfig,
  });
  String checkSession([String? expected]) {
    final uid = session.userId;
    if (uid == null ||
        auth.currentUser?.uid != uid ||
        (expected != null && uid != expected)) {
      throw const AiChatFailure(
        'Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.',
      );
    }
    return uid;
  }

  Future<AiModelConfig> config() async {
    final uid = checkSession();
    final json = await loadConfig();
    checkSession(uid);
    return AiModelConfig.fromJson(json);
  }

  Future<Map<String, dynamic>> generate({
    required AiModelConfig config,
    required String guide,
    required String prompt,
    required String expectedUid,
    List<AiMessage> history = const [],
    Uint8List? image,
    String? mimeType,
    int maxTokens = 2048,
  }) async {
    checkSession(expectedUid);
    if (image != null &&
        (image.isEmpty ||
            image.length > 4 * 1024 * 1024 ||
            !['image/jpeg', 'image/png', 'image/webp'].contains(mimeType))) {
      throw const AiChatFailure('Chọn ảnh JPEG, PNG hoặc WebP tối đa 4 MB.');
    }
    final gemini = config.gemini;
    final url = gemini
        ? Uri.https(
            'generativelanguage.googleapis.com',
            '/v1beta/models/${config.model}:generateContent',
          )
        : Uri.parse(
            '${config.endpoint.toString().replaceAll(RegExp(r'/+$'), '')}/chat/completions',
          );
    final body = gemini
        ? {
            'systemInstruction': {
              'parts': [
                {'text': guide},
              ],
            },
            'contents': [
              ...history.map(
                (m) => {
                  'role': m.fromAi ? 'model' : 'user',
                  'parts': [
                    {'text': m.text},
                  ],
                },
              ),
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                  if (image != null)
                    {
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Encode(image),
                      },
                    },
                ],
              },
            ],
            'generationConfig': {
              'maxOutputTokens': maxTokens,
              'responseMimeType': 'application/json',
            },
          }
        : {
            'model': config.model,
            'messages': [
              {'role': 'system', 'content': guide},
              ...history.map((m) => {'role': m.role, 'content': m.text}),
              {
                'role': 'user',
                'content': image == null
                    ? prompt
                    : [
                        {'type': 'text', 'text': prompt},
                        {
                          'type': 'image_url',
                          'image_url': {
                            'url':
                                'data:$mimeType;base64,${base64Encode(image)}',
                          },
                        },
                      ],
              },
            ],
            config.endpoint.host == 'api.openai.com'
                    ? 'max_completion_tokens'
                    : 'max_tokens':
                maxTokens,
            'response_format': {'type': 'json_object'},
          };
    try {
      final response = await client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (gemini)
                'x-goog-api-key': config.key
              else
                'Authorization': 'Bearer ${config.key}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));
      checkSession(expectedUid);
      if (response.statusCode != 200) {
        throw AiChatFailure(
          response.statusCode == 429
              ? 'API AI đã hết quota hoặc giới hạn lượt dùng (HTTP 429).'
              : response.statusCode == 404
              ? 'Model không dùng được với key (HTTP 404). Nhờ admin chọn model mới.'
              : image != null && response.statusCode == 400
              ? 'Model đang dùng chưa nhận được ảnh này. Thử nhập món bằng chữ hoặc chọn model hỗ trợ ảnh trong cấu hình AI chung.'
              : 'API AI từ chối yêu cầu (HTTP ${response.statusCode}).',
        );
      }
      if (response.bodyBytes.length > 256000) {
        throw const AiChatFailure('Câu trả lời AI quá dài.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = gemini
          ? (data['candidates'] as List?)?.firstOrNull?['content']?['parts']
                ?.where((p) => p['thought'] != true)
                .map((p) => p['text'] ?? '')
                .join('')
          : data['choices']?[0]?['message']?['content'];
      if (raw is! String || raw.contains(config.key)) {
        throw const AiChatFailure('AI chưa trả nội dung phù hợp.');
      }
      return Map<String, dynamic>.from(
        jsonDecode(
          raw
              .trim()
              .replaceFirst(
                RegExp(r'^```(?:json)?\s*', caseSensitive: false),
                '',
              )
              .replaceFirst(RegExp(r'\s*```$'), ''),
        ) as Map,
      );
    } on AiChatFailure {
      rethrow;
    } on TimeoutException {
      throw const AiChatFailure('AI phản hồi quá lâu. Vui lòng gửi lại.');
    } catch (_) {
      throw const AiChatFailure(
        'Chưa gọi được AI. Kiểm tra mạng hoặc cấu hình model chung.',
      );
    }
  }
}
