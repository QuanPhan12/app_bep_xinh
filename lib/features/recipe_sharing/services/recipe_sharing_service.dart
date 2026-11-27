import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

import '../../kitchen/models/kitchen_entry.dart';

bool recordsShareResult(ShareResultStatus status, {required bool web}) =>
    status == ShareResultStatus.success ||
    (web && status == ShareResultStatus.unavailable);

class RecipeSharingService {
  final Uri base;
  final Future<void> Function(String recipeId, String channel)? record;
  final Future<ShareResult> Function(ShareParams) _shareSheet;
  RecipeSharingService({
    this.record,
    Future<ShareResult> Function(ShareParams)? shareSheet,
    String publicAppUrl = const String.fromEnvironment(
      'PUBLIC_APP_URL',
      defaultValue: 'https://bepxinh-b0be7.web.app',
    ),
  }) : base = Uri.parse(publicAppUrl),
       _shareSheet = shareSheet ?? SharePlus.instance.share {
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
    final result = await _shareSheet(
      ShareParams(uri: link(recipeId), sharePositionOrigin: origin),
    );
    // Web trả unavailable sau Web Share/mailto thành công; hủy vẫn trả dismissed.
    if (recordsShareResult(result.status, web: kIsWeb)) {
      unawaited(_record(recipeId, 'sheet'));
    }
  }

  Future<void> copy(String recipeId) async {
    await Clipboard.setData(ClipboardData(text: link(recipeId).toString()));
    unawaited(_record(recipeId, 'copy'));
  }

  Future<void> _record(String recipeId, String channel) async {
    try {
      await record?.call(recipeId, channel);
    } catch (_) {
      // Lỗi ghi thống kê không biến thao tác chia sẻ/sao chép đã xong thành thất bại.
    }
  }
}
