import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../dimensions/app_size.dart';
import '../text_styles/app_text_styles.dart';
import 'app_tap.dart';

/// Thanh tìm kiếm của Home, dùng chung cho dạng mở trang và nhập trực tiếp.
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Key? fieldKey;
  final int? maxLength;
  final EdgeInsetsGeometry padding;
  final String? actionName;
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.initialValue = '',
    this.onChanged,
    this.onTap,
    this.fieldKey,
    this.maxLength,
    this.padding = EdgeInsets.zero,
    this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp(context));
    final content = Container(
      height: 48.h(context),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r(context)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w(context)),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            color: AppColors.textTertiary,
            size: 20.sp(context),
          ),
          SizedBox(width: 10.w(context)),
          Expanded(
            child: onChanged == null
                ? Text(
                    hintText,
                    style: style.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : TextFormField(
                    key: fieldKey,
                    initialValue: initialValue,
                    onChanged: onChanged,
                    maxLength: maxLength,
                    style: style.copyWith(color: AppColors.textPrimary),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: style.copyWith(color: AppColors.textTertiary),
                      isCollapsed: true,
                      filled: false,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
          ),
        ],
      ),
    );
    return Padding(
      padding: padding,
      child: onChanged == null
          ? AppTap(actionName: actionName, onTap: onTap, child: content)
          : content,
    );
  }
}
