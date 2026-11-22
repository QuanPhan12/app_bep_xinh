import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../kitchen/models/kitchen_entry.dart';

class RecipeSharingService {
  final Uri base;
  RecipeSharingService({
    String publicAppUrl = const String.fromEnvironment(
      'PUBLIC_APP_URL',
      defaultValue: 'https://bepxinh-b0be7.web.app',
    ),
  }) : base = Uri.parse(publicAppUrl) {
    if (base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw ArgumentError('PUBLIC_APP_URL cần là HTTPS hợp lệ.');
    }
  }
  Uri link(String recipeId) => Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    pathSegments: ['recipe', kitchenKey(recipeId)],
  );
  Future<void> share(String recipeId, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(uri: link(recipeId), sharePositionOrigin: origin),
    );
  }

  Future<void> copy(String recipeId) =>
      Clipboard.setData(ClipboardData(text: link(recipeId).toString()));
}
