import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';

import '../cubits/profile_edit/profile_edit_cubit.dart';
import '../services/profile_service.dart';
import '../../recipes/widgets/recipe_image_view.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ProfileEditCubit(service: context.read<ProfileService>())..load(),
    child: const _ProfileEditPage(),
  );
}

class _ProfileEditPage extends StatefulWidget {
  const _ProfileEditPage();
  @override
  State<_ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<_ProfileEditPage> {
  bool _leaving = false;
  bool _confirming = false;

  Future<void> _requestBack(BuildContext context) async {
    final cubit = context.read<ProfileEditCubit>();
    if (_leaving ||
        cubit.state.saving ||
        cubit.state.pickingAvatar ||
        _confirming) {
      return;
    }
    if (cubit.hasUnsavedChanges) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Bỏ thay đổi hồ sơ?'),
          content: const Text(
            'Các thay đổi chưa được lưu. Bạn có thể ở lại để tiếp tục chỉnh sửa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true || !context.mounted) return;
    }
    if (!mounted) return;
    // PopScope cần nhận trạng thái cho phép rời màn trước khi thực hiện pop.
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) _back(context);
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PathRouter.settingsScreen);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProfileEditCubit, ProfileEditState>(
        listenWhen: (a, b) => a.saved != b.saved || a.noticeId != b.noticeId,
        listener: (context, state) {
          if (state.saved) {
            AppMessenger.showSuccess(context, 'Đã cập nhật hồ sơ.');
            _requestBack(context);
          } else if (state.message != null) {
            AppMessenger.showError(context, state.message!);
          }
        },
        builder: (context, state) {
          final cubit = context.read<ProfileEditCubit>();
          return PopScope(
            canPop:
                !state.saving &&
                !state.pickingAvatar &&
                (_leaving || !cubit.hasUnsavedChanges),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _requestBack(context);
            },
            child: AppPageScaffold(
              appBar: AppSliverAppBar(
                title: 'Chỉnh sửa hồ sơ',
                backEnabled: !state.saving && !state.pickingAvatar,
                onBackPressed: () => _requestBack(context),
              ),
              body: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppLayout.formWidth(context),
                    ),
                    child: state.loading || state.loadFailed
                        ? AppLoadState(
                            isLoading: state.loading,
                            message: state.message,
                            onRetry: cubit.load,
                          )
                        : AppContentScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.all(20),
                            children: [
                              Center(
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: state.avatar != null
                                        ? RecipeImageView(image: state.avatar!)
                                        : AppAvatar(
                                            name: state.name,
                                            imageUrl: state.avatarUrl,
                                            size: 88,
                                          ),
                                  ),
                                ),
                              ),
                              if (cubit.canChangeAvatar)
                                TextButton.icon(
                                  onPressed: state.saving || state.pickingAvatar
                                      ? null
                                      : cubit.pickAvatar,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(
                                    state.pickingAvatar
                                        ? 'Đang chọn ảnh…'
                                        : 'Đổi ảnh đại diện',
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
                                error: state.showErrors
                                    ? state.nameError
                                    : null,
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
            ),
          );
        },
      );
}
