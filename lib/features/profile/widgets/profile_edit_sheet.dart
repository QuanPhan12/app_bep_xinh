import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';

import '../cubits/profile_edit/profile_edit_cubit.dart';
import '../models/profile_data.dart';
import '../services/profile_service.dart';

Future<void> showProfileEditSheet(
  BuildContext context,
  UserProfile account,
) async {
  final service = context.read<ProfileService>();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    constraints: BoxConstraints(maxWidth: AppLayout.sheetWidth(context)),
    builder: (context) => BlocProvider(
      create: (_) => ProfileEditCubit(service: service, account: account),
      child: const _ProfileEditForm(),
    ),
  );
  if (saved == true && context.mounted) {
    AppMessenger.showSuccess(context, 'Đã cập nhật hồ sơ.');
  }
}

class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm();
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProfileEditCubit, ProfileEditState>(
        listenWhen: (a, b) => a.saved != b.saved || a.noticeId != b.noticeId,
        listener: (context, state) {
          if (state.saved) {
            Navigator.of(context).pop(true);
          } else if (state.message != null) {
            AppMessenger.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          final cubit = context.read<ProfileEditCubit>();
          final media = MediaQuery.of(context);
          return PopScope(
            canPop: !state.saving,
            child: Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (media.size.height * .85 - media.viewInsets.bottom)
                      .clamp(180, media.size.height * .85),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: 'Chỉnh sửa hồ sơ',
                        action: IconButton(
                          tooltip: 'Đóng',
                          onPressed: state.saving
                              ? null
                              : context.onAppTap(
                                  () => Navigator.of(context).pop(),
                                  actionName: 'profile_edit_close',
                                  allowConcurrent: true,
                                ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        fieldId: 'profile_name',
                        initialValue: state.name,
                        hint: 'Tên của bạn',
                        label: 'Tên hiển thị',
                        maxLength: 60,
                        enabled: !state.saving,
                        onChanged: cubit.changeName,
                        error: state.showErrors ? state.nameError : null,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        fieldId: 'profile_bio',
                        initialValue: state.bio,
                        hint: 'Chia sẻ một chút về góc bếp của bạn',
                        label: 'Giới thiệu',
                        maxLength: 200,
                        minLines: 3,
                        maxLines: 4,
                        enabled: !state.saving,
                        onChanged: cubit.changeBio,
                        error: state.showErrors ? state.bioError : null,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Lưu thay đổi',
                        actionName: 'profile_save',
                        onPressed: cubit.save,
                        isLoading: state.saving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
