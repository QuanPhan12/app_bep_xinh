import 'package:flutter/material.dart';

import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../../core/widgets/widgets.dart';

Future<T?> showKitchenEntryForm<T>(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext, StateSetter) fields,
  required T Function() value,
  required Future<bool> Function(T) save,
}) async {
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  final result = await showAppAdaptiveSheet<T>(
    context: context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => PopScope(
        canPop: !busy,
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height:
                  (constraints.maxHeight -
                          MediaQuery.viewInsetsOf(context).bottom)
                      .clamp(0, 660),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: form,
                          child: IgnorePointer(
                            ignoring: busy,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: fields(context, setState),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Màn gọi có thể đang await dialog trong AppTapHandler; form tự khóa khi lưu.
                    AppButton(
                      text: 'Lưu',
                      allowConcurrent: true,
                      isLoading: busy,
                      onPressed: busy
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              T next;
                              try {
                                next = value();
                              } catch (e) {
                                setState(
                                  () => error = e is FormatException
                                      ? e.message.toString()
                                      : 'Kiểm tra lại dữ liệu.',
                                );
                                return;
                              }
                              setState(() {
                                busy = true;
                                error = null;
                              });
                              var saved = false;
                              try {
                                saved = await save(next);
                              } catch (_) {
                                saved = false;
                              }
                              if (!context.mounted) return;
                              if (saved) {
                                Navigator.of(context).pop(next);
                              } else {
                                setState(() {
                                  busy = false;
                                  error = 'Chưa lưu được thay đổi. Kiểm tra dữ liệu hoặc kết nối và thử lại.';
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return result;
}

Widget kitchenInput(
  TextEditingController controller,
  String label, {
  int maxLength = 60,
  bool number = false,
  int lines = 1,
  bool required = true,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    controller: controller,
    maxLength: maxLength,
    minLines: lines,
    maxLines: lines,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    decoration: InputDecoration(labelText: label, counterText: ''),
    validator: (value) => required && (value?.trim().isEmpty ?? true)
        ? 'Vui lòng nhập $label.'
        : null,
  ),
);
