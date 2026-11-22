import 'package:app_bep_xinh/sollume/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/theme/app_radius.dart';

/// Ô nhập dùng chung; nhận dữ liệu từ state qua value/onChanged nếu cần đồng bộ.
///
/// Kế thừa màu, border, padding và font từ ThemeData của app.
/// Không dùng .sp lần nữa vì textTheme đã được responsive.
/// Không khóa chiều cao để lỗi, nội dung nhiều dòng và chữ hệ thống lớn
/// có thể hiển thị. Form bên ngoài nên cuộn được khi bàn phím mở.
///
/// Ví dụ:
/// ```dart
/// AppTextField(
///   onChanged: context.read<LoginCubit>().emailChanged,
///   hintText: 'Nhập email',
///   keyboardType: TextInputType.emailAddress,
///   autofillHints: const [AutofillHints.email],
///   validator: (value) => value == null || value.trim().isEmpty
///       ? 'Vui lòng nhập email' : null,
/// );
///
/// AppTextField(
///   hintText: 'Nhập mật khẩu',
///   isPassword: true,
///   obscureText: !state.isPasswordVisible,
///   onTogglePasswordVisibility:
///       context.read<LoginCubit>().togglePasswordVisibility,
///   onChanged: context.read<LoginCubit>().passwordChanged,
///   textInputAction: TextInputAction.done,
///   autofillHints: const [AutofillHints.password],
/// );
/// ```
///
/// Cubit nhận dữ liệu qua onChanged và cung cấp trạng thái hiển thị/lỗi.
/// value đồng bộ nội dung từ state; chỉ tạo controller nội bộ khi có value.
/// Không truyền value/controller thì TextFormField tự quản lý việc nhập liệu.
/// initialValue chỉ có tác dụng lúc khởi tạo, không đồng bộ các lần emit sau.
/// Nếu reset Form, cần reset cả dữ liệu Cubit vì onChanged không chạy khi reset.
/// Controller và FocusNode truyền vào do widget cha tạo và dispose.
/// Không phụ thuộc Cubit cụ thể.
class AppTextField extends StatefulWidget {
  /// Preset tìm kiếm giữ nguyên controller/focus/clear của field dùng chung.
  factory AppTextField.search({
    Key? key,
    String? value,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    String hintText = 'Tìm kiếm',
    String clearButtonLabel = 'Xóa tìm kiếm',
    ValueChanged<String>? onSubmitted,
  }) => AppTextField(
    key: key,
    value: value,
    onChanged: onChanged,
    onClear: onClear,
    hintText: hintText,
    clearButtonLabel: clearButtonLabel,
    onSubmitted: onSubmitted,
    radius: AppRadius.search,
    showFocusedBorder: false,
    textInputAction: TextInputAction.search,
    prefixIcon: const PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 20),
    prefixIconPadding: const EdgeInsetsDirectional.only(start: 14, end: 4),
  );
  const AppTextField({
    super.key,
    this.initialValue,
    this.value,
    this.controller,
    this.focusNode,
    this.hintText,
    this.filled,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.prefixIconPadding,
    this.suffixIcon,
    this.radius,
    this.showFocusedBorder = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.obscureText = true,
    this.onTogglePasswordVisibility,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = false,
    this.enableSuggestions = true,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.inputFormatters,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.validator,
    this.onChanged,
    this.onClear,
    this.clearButtonLabel = 'Xóa nội dung',
    this.onSubmitted,
    this.onSaved,
    this.onTap,
    this.scrollPadding = const EdgeInsets.all(24),
    this.showPasswordLabel = 'Hiện mật khẩu',
    this.hidePasswordLabel = 'Ẩn mật khẩu',
  }) : assert(controller == null || initialValue == null),
       assert(value == null || (controller == null && initialValue == null)),
       assert(
         onClear == null ||
             (value != null &&
                 suffixIcon == null &&
                 onTogglePasswordVisibility == null),
         'onClear dùng cùng value và không dùng chung với suffixIcon/nút mật khẩu.',
       ),
       assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(maxLines == null || minLines == null || minLines <= maxLines),
       assert(
         !isPassword || (maxLines == 1 && (minLines == null || minLines == 1)),
         'Ô mật khẩu chỉ hỗ trợ một dòng.',
       ),
       assert(
         !isPassword ||
             onTogglePasswordVisibility == null ||
             suffixIcon == null,
         'Chỉ truyền onTogglePasswordVisibility hoặc suffixIcon cho mật khẩu.',
       ),
       assert(
         maxLength == null ||
             maxLength > 0 ||
             maxLength == TextField.noMaxLength,
       ),
       assert(radius == null || (radius >= 0 && radius < double.infinity));

  final String? initialValue;

  /// Giá trị từ state, không dùng cùng initialValue hoặc controller.
  final String? value;

  /// Controller tùy chọn do UI bên ngoài sở hữu; không dùng cùng initialValue.
  final TextEditingController? controller;
  final FocusNode? focusNode;

  final String? hintText;
  final bool? filled;
  final String? helperText;

  /// Lỗi bên ngoài (ví dụ từ API). Xóa lỗi này khi người dùng sửa nội dung.
  /// Khi khác null, forceErrorText ưu tiên lỗi này và không chạy validator.
  final String? errorText;

  final Widget? prefixIcon;

  /// Khoảng cách trước/sau icon; null giữ vùng icon mặc định của Material.
  final EdgeInsetsGeometry? prefixIconPadding;
  final Widget? suffixIcon;

  /// Bo góc riêng cho ô nhập; để null để kế thừa bán kính từ theme.
  final double? radius;

  /// Tắt để ẩn viền focus thường; viền báo lỗi vẫn lấy từ theme.
  final bool showFocusedBorder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool isPassword;
  final bool obscureText;

  /// Truyền callback để hiện nút ẩn/hiện; widget cha cập nhật obscureText.
  final VoidCallback? onTogglePasswordVisibility;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode autovalidateMode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  /// Hiện nút xóa khi value có nội dung; callback cập nhật giá trị tại nguồn state.
  final VoidCallback? onClear;
  final String clearButtonLabel;
  final ValueChanged<String>? onSubmitted;
  final FormFieldSetter<String>? onSaved;
  final VoidCallback? onTap;
  final EdgeInsets scrollPadding;
  final String showPasswordLabel;
  final String hidePasswordLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();

  Widget _buildField(
    BuildContext context, {
    TextEditingController? textController,
    FocusNode? inputFocusNode,
    VoidCallback? clear,
  }) {
    final theme = Theme.of(context);
    InputBorder? withRadius(InputBorder? border) {
      if (radius == null || border == null) return null;
      final borderRadius = BorderRadius.circular(radius!);
      return switch (border) {
        OutlineInputBorder() => border.copyWith(borderRadius: borderRadius),
        UnderlineInputBorder() => border.copyWith(borderRadius: borderRadius),
        _ => border,
      };
    }

    final decorationTheme = theme.inputDecorationTheme;
    final unfocusedBorder =
        decorationTheme.enabledBorder ??
        decorationTheme.border ??
        const OutlineInputBorder();
    final password = isPassword;
    final multiline = maxLines != 1;
    final showToggle = password && onTogglePasswordVisibility != null;
    final suffix = showToggle
        ? IconButton(
            onPressed: enabled ? onTogglePasswordVisibility : null,
            tooltip: context.uiLabel(
              obscureText ? showPasswordLabel : hidePasswordLabel,
            ),
            // Icon is small but its interactive area stays at least 48x48.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: PhosphorIcon(
              obscureText ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        : clear != null
        ? Semantics(
            label: context.uiLabel(clearButtonLabel),
            child: IconButton(
              onPressed: enabled && !readOnly ? clear : null,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: PhosphorIcon(
                PhosphorIconsRegular.x,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : suffixIcon;

    return TextFormField(
      initialValue: textController == null ? initialValue : null,
      controller: textController,
      focusNode: inputFocusNode,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
      ),

      decoration: InputDecoration(
        filled: filled,
        border: withRadius(
          decorationTheme.border ?? const OutlineInputBorder(),
        ),
        enabledBorder: withRadius(decorationTheme.enabledBorder),
        disabledBorder: withRadius(decorationTheme.disabledBorder),
        focusedBorder: showFocusedBorder
            ? withRadius(decorationTheme.focusedBorder)
            : (withRadius(unfocusedBorder) ?? unfocusedBorder).copyWith(
                borderSide: BorderSide.none,
              ),
        errorBorder: withRadius(decorationTheme.errorBorder),
        focusedErrorBorder: withRadius(decorationTheme.focusedErrorBorder),
        hintText: hintText == null ? null : context.uiLabel(hintText!),
        helper: helperText == null
            ? null
            : Text(
                context.uiLabel(helperText!),
                style:
                    theme.inputDecorationTheme.helperStyle ??
                    theme.textTheme.bodySmall,
              ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIcon: prefixIcon == null || prefixIconPadding == null
            ? prefixIcon
            : Padding(padding: prefixIconPadding!, child: prefixIcon),
        // Cho phép thu gọn chiều rộng icon nhưng vẫn giữ chiều cao ô nhập >= 48.
        prefixIconConstraints: prefixIconPadding == null
            ? null
            : const BoxConstraints(minHeight: 48),
        suffixIcon: suffix,
      ),
      forceErrorText: context.uiError(errorText),
      errorBuilder: (context, error) => Text(
        context.uiError(error)!,
        style:
            (theme.inputDecorationTheme.errorStyle ?? theme.textTheme.bodySmall)
                ?.copyWith(color: theme.colorScheme.error),
      ),
      keyboardType:
          keyboardType ??
          (password
              ? TextInputType.visiblePassword
              : multiline
              ? TextInputType.multiline
              : TextInputType.text),
      textInputAction:
          textInputAction ??
          (multiline ? TextInputAction.newline : TextInputAction.next),
      textCapitalization: password
          ? TextCapitalization.none
          : textCapitalization,
      obscureText: password && obscureText,
      autocorrect: password ? false : autocorrect,
      enableSuggestions: password ? false : enableSuggestions,
      enableIMEPersonalizedLearning: !password,
      smartDashesType: password ? SmartDashesType.disabled : null,
      smartQuotesType: password ? SmartQuotesType.disabled : null,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      textAlignVertical: multiline
          ? TextAlignVertical.top
          : TextAlignVertical.center,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onSaved: onSaved,
      onTap: onTap,
      scrollPadding: scrollPadding,
    );
  }
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _valueController;
  FocusNode? _clearFocusNode;

  @override
  void initState() {
    super.initState();
    _syncResources();
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncResources();
    if (widget.value == null &&
        widget.controller == null &&
        oldWidget.controller != null &&
        _valueController != null) {
      _valueController!.value = oldWidget.controller!.value;
    }
  }

  void _syncResources() {
    final value = widget.value;
    if (value != null) {
      _valueController ??= TextEditingController(text: value);
      // State phản hồi đúng nội dung đang gõ: giữ nguyên cursor và composing.
      if (_valueController!.text != value) {
        _valueController!.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }
    if (widget.onClear != null && widget.focusNode == null) {
      _clearFocusNode ??= FocusNode();
    }
  }

  void _clear() {
    widget.onClear?.call();
    (widget.focusNode ?? _clearFocusNode)?.requestFocus();
  }

  @override
  void dispose() {
    _valueController?.dispose();
    _clearFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget._buildField(
    context,
    textController: widget.controller ?? _valueController,
    inputFocusNode: widget.focusNode ?? _clearFocusNode,
    clear: widget.onClear != null && widget.value!.isNotEmpty ? _clear : null,
  );
}
