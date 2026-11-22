import 'package:flutter/widgets.dart';

/// Bếp Xinh chỉ nối nhãn UI tiếng Việt; không sao chép locale nghiệp vụ Sollume.
extension SollumeUiLabels on BuildContext {
  String uiLabel(String label) => label;
  String? uiError(String? message) => message;
  SollumeUiMessages get l10n => const SollumeUiMessages();
}

class SollumeUiMessages {
  const SollumeUiMessages();
  String actionProcessing(String label) => 'Đang xử lý $label';
}
