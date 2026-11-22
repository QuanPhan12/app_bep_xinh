import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/password_service.dart';
import 'package:app_bep_xinh/features/settings/cubits/password_cubit.dart';
import 'package:app_bep_xinh/features/profile/cubits/profile_edit/profile_edit_cubit.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/cooking_timers/widgets/recipe_active_timers.dart';
import 'package:app_bep_xinh/features/cooking_timers/services/cooking_timer_service.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';

import '../support/profile_fakes.dart';
import '../support/kitchen_fakes.dart';
import '../support/test_text_styles.dart';
import '../support/auth_fake.dart';

import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/settings/screens/change_password_screen.dart';
import 'package:app_bep_xinh/features/settings/screens/legal_screen.dart';

class PasswordAuthFake extends StubAuthService implements PasswordService {
  @override
  bool get canChangePassword => true;
  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}
}

class PasswordFake implements PasswordService {
  int calls = 0;
  Future<void> Function()? onChange;
  @override
  bool get canChangePassword => true;
  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    calls++;
    await onChange?.call();
  }
}

class AvatarFake extends StubProfileService implements ProfileAvatarService {
  RecipeImage? selected;
  Future<RecipeImage?> Function()? onPick;
  bool fail = false;
  @override
  Future<RecipeImage?> pickAvatar() async =>
      onPick != null ? await onPick!() : selected;
  @override
  Future<UserProfile> updateProfileWithAvatar({
    required String name,
    required String bio,
    required RecipeImage image,
  }) async {
    writes++;
    if (fail) throw StateError('offline');
    publish(account.copyWith(name: name, bio: bio));
    return account;
  }
}

class CameraPickerFake extends ImagePicker {
  ImageSource? source;
  XFile? image;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    return image;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestTextStyles);
  test('Legal routes are public; password route requires authentication', () {
    final auth = StubAuthService();
    addTearDown(auth.dispose);
    expect(authRedirect(auth, Uri.parse('/legal/terms')), isNull);
    expect(authRedirect(auth, Uri.parse('/legal/privacy')), isNull);
    expect(
      authRedirect(auth, Uri.parse('/settings/password')),
      startsWith('/login'),
    );
  });
  testWidgets(
    'Password and legal pages support small/tablet screens, large text and keyboard',
    (tester) async {
      final auth = PasswordAuthFake();
      addTearDown(auth.dispose);
      for (final width in [320.0, 800.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        for (final dark in [false, true]) {
          for (final page in [
            const ChangePasswordScreen(),
            const LegalScreen(privacy: true),
          ]) {
            await tester.pumpWidget(
              RepositoryProvider<AuthService>.value(
                value: auth,
                child: MaterialApp(
                  theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 900),
                      textScaler: const TextScaler.linear(1.5),
                      viewInsets: const EdgeInsets.only(bottom: 280),
                    ),
                    child: page,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    },
  );
  test('Password validation prevents writes; failure preserves draft and retry clears secrets', () async {
    final service = PasswordFake(), cubit = PasswordCubit(PasswordFake());
    await cubit.save();
    expect(cubit.state.error, isNotNull);
    await cubit.close();
    final edit = PasswordCubit(service);
    addTearDown(edit.close);
    edit.change(current: 'old-123', password: 'new-123', confirm: 'wrong');
    await edit.save();
    expect(service.calls, 0);
    edit.change(confirm: 'new-123');
    service.onChange = () async =>
        throw const AuthFailure('Sai mật khẩu hiện tại.');
    await edit.save();
    expect(edit.state.saved, isFalse);
    expect(edit.state.password, 'new-123');
    service.onChange = null;
    await edit.save();
    expect(edit.state.saved, isTrue);
    expect(edit.state.current, isEmpty);
    expect(edit.state.password, isEmpty);
  });
  test('Changing password guards duplicate submits and late completion after close', () async {
    final pending = Completer<void>(), service = PasswordFake();
    service.onChange = () => pending.future;
    final cubit = PasswordCubit(service);
    cubit.change(current: 'old-123', password: 'new-123', confirm: 'new-123');
    final saving = cubit.save();
    await cubit.save();
    cubit.change(password: 'ignored');
    expect(service.calls, 1);
    expect(cubit.state.password, 'new-123');
    await cubit.close();
    pending.complete();
    await saving;
  });
  test('Avatar selection cancel preserves draft; failed save retains image for retry', () async {
    final service = AvatarFake();
    addTearDown(service.dispose);
    final cubit = ProfileEditCubit(service: service, account: service.account);
    addTearDown(cubit.close);
    service.selected = const RecipeImage.asset(
      id: 'a',
      assetPath: 'assets/images/logo.png',
    );
    await cubit.pickAvatar();
    expect(cubit.hasUnsavedChanges, isTrue);
    service.selected = null;
    await cubit.pickAvatar();
    expect(cubit.state.avatar?.id, 'a');
    service.fail = true;
    await cubit.save();
    expect(cubit.state.saved, isFalse);
    expect(cubit.state.avatar, isNotNull);
    service.fail = false;
    await cubit.save();
    expect(cubit.state.saved, isTrue);
  });
  test(
    'Avatar picking blocks saving and ignores a result after close',
    () async {
      final service = AvatarFake(), pending = Completer<RecipeImage?>();
      addTearDown(service.dispose);
      service.onPick = () => pending.future;
      final cubit = ProfileEditCubit(
        service: service,
        account: service.account,
      );
      final picking = cubit.pickAvatar();
      await cubit.save();
      expect(service.writes, 0);
      await cubit.close();
      pending.complete(
        const RecipeImage.asset(id: 'a', assetPath: 'assets/images/logo.png'),
      );
      await picking;
    },
  );
  test('Camera uses camera source; cancel does not create a photo', () async {
    final picker = CameraPickerFake(),
        adapter = ImagePickerRecipeCoverPicker(picker: CameraPickerFake());
    expect(await adapter.captureCover(), isNull);
    final camera = ImagePickerRecipeCoverPicker(picker: picker);
    picker.image = XFile.fromData(
      File('assets/images/logo.png').readAsBytesSync(),
      name: 'camera.png',
    );
    final image = await camera.captureCover();
    expect(picker.source, ImageSource.camera);
    expect(image?.bytes, isNotEmpty);
    await camera.pickCover();
    expect(picker.source, ImageSource.gallery);
  });
  testWidgets(
    'Recipe countdown ticks inline, pauses and reaches zero without leaving cooking',
    (tester) async {
      var now = DateTime.utc(2026, 11, 17);
      final timer = CookingTimerService(
        storage: MemoryKitchenStorage(),
        storageKey: 'test.timer',
        checkSession: () {},
        now: () => now,
      );
      final kitchen = kitchenFixture(timers: timer);
      await timer.start('Trứng · Bước 1', const Duration(seconds: 3));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KitchenScope(
              services: kitchen,
              child: const RecipeActiveTimers(recipeTitle: 'Trứng'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('00:03'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02'), findsOneWidget);
      await tester.tap(find.text('Tạm dừng'));
      await tester.pump();
      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump();
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Đã hết giờ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await disposeKitchen(kitchen);
    },
  );
}
