import 'features/recipes/services/published_recipe_source.dart';
import 'features/ai_chat/services/ai_chat_repository.dart';
import 'features/ai_chat/services/direct_ai_chat_repository.dart';
import 'features/ai_chat/services/firestore_direct_ai_store.dart';
import 'features/ai_chat/widgets/ai_chat_session_scope.dart';
import 'features/kitchen/services/kitchen_services.dart';
import 'features/home/widgets/home_unread_scope.dart';
import 'features/messages/services/chat_image_service.dart';
import 'features/notifications/services/notification_repository.dart';
import 'features/notifications/services/firestore_notification_repository.dart';
import 'features/messages/services/message_repository.dart';
import 'features/messages/services/firestore_message_repository.dart';
import 'features/recipe_editor/services/recipe_submission_service.dart';
import 'features/profile/services/published_public_profile_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'core/services/firestore_user_store.dart';
import 'features/auth/services/auth_service.dart';
import 'features/profile/services/firestore_profile_service.dart';
import 'features/recipes/services/firestore_recipe_favorites_service.dart';
import 'features/recipe_search/services/recipe_search_service.dart';
import 'features/recipe_search/services/search_history_repository.dart';
import 'features/recipe_detail/services/recipe_detail_service.dart';
import 'features/recipes/services/recipe_favorites_service.dart';
import 'features/profile/services/profile_service.dart';
import 'features/profile/services/public_profile_service.dart';
import 'features/ingredients/services/ingredient_catalog_service.dart';
import 'features/ingredients/services/firestore_ingredient_catalog_service.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/app_theme_cubit.dart';
import 'core/services/mock_api_client.dart';
import 'features/fridge/services/fridge_service.dart';
import 'features/fridge/services/remote_fridge_service.dart';
import 'features/fridge/services/firestore_fridge_inventory_repository.dart';
import 'features/home/services/home_service.dart';
import 'features/recipe_editor/services/recipe_editor_service.dart';
import 'features/recipe_editor/services/recipe_cover_picker.dart';
import 'features/recipe_editor/services/cloudinary_recipe_image_uploader.dart';
import 'features/recipe_editor/services/recipe_image_uploader.dart';
import 'features/recipe_editor/services/firestore_recipe_editor_service.dart';
import 'features/recipe_editor/services/firestore_recipe_authoring_repository.dart';

import 'package:http/http.dart' as http;

/* Widget gốc khởi chạy ứng dụng Bếp Xinh */
class AppBepXinh extends StatefulWidget {
  final AuthService authService;
  const AppBepXinh({super.key, required this.authService});

  @override
  State<AppBepXinh> createState() => _AppBepXinhState();
}

class _AppBepXinhState extends State<AppBepXinh> {
  late final GoRouter _router = createAppRouter(auth: widget.authService);
  late final AppThemeCubit _theme = AppThemeCubit(LocalThemePreference())
    ..load();

  @override
  void dispose() {
    _router.dispose();
    unawaited(_theme.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authService.sessionChanges,
      builder: (context, _) => MultiRepositoryProvider(
        // Tạo lại service và widget theo UID để không lộ dữ liệu tài khoản trước.
        key: ValueKey(widget.authService.userId),
        providers: [
          RepositoryProvider<PublishedRecipeSource>(
            create: (_) => PublishedRecipeSource(FirebaseFirestore.instance),
          ),
          RepositoryProvider<AuthService>.value(value: widget.authService),
          RepositoryProvider<FirestoreUserStore>(
            create: (_) => FirestoreUserStore(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
              uid: widget.authService.userId ?? '',
            ),
          ),
          RepositoryProvider<NotificationRepository>(
            create: (context) => FirestoreNotificationRepository(
              context.read<FirestoreUserStore>(),
            ),
          ),
          RepositoryProvider<MessageRepository>(
            create: (context) => FirestoreMessageRepository(
              store: context.read<FirestoreUserStore>(),
              published: context.read<PublishedRecipeSource>(),
            ),
          ),
          RepositoryProvider<MockApiClient>(create: (_) => MockApiClient()),
          RepositoryProvider<IngredientCatalogService>(
            create: (context) =>
                FirestoreIngredientCatalogService(FirebaseFirestore.instance),
          ),
          RepositoryProvider<FridgeService>(
            create: (context) => RemoteFridgeService(
              inventory: FirestoreFridgeInventoryRepository(
                context.read<FirestoreUserStore>(),
              ),
              catalog: context.read<IngredientCatalogService>(),
              readPublished: context
                  .read<PublishedRecipeSource>()
                  .fetchPublished,
            ),
            dispose: (service) => unawaited(service.dispose()),
          ),
          RepositoryProvider<RecipeFavoritesService>(
            create: (context) => FirestoreRecipeFavoritesService(
              context.read<FirestoreUserStore>(),
            ),
            dispose: (service) => unawaited(service.dispose()),
          ),
          RepositoryProvider<RecipeDetailService>(
            create: (context) => MockRecipeDetailService(
              context.read<MockApiClient>(),
              context.read<IngredientCatalogService>(),
              context.read<FridgeService>(),
              context.read<RecipeFavoritesService>(),
              published: context.read<PublishedRecipeSource>(),
            ),
          ),
          RepositoryProvider<MockProfileService>(
            create: (context) => MockProfileService(
              context.read<MockApiClient>(),
              context.read<RecipeFavoritesService>(),
            ),
            dispose: (service) => unawaited(service.dispose()),
          ),
          RepositoryProvider<http.Client>(
            create: (_) => http.Client(),
            dispose: (client) => client.close(),
          ),
          RepositoryProvider<AiChatRepository>(
            create: (context) => DirectAiChatRepository(
              client: context.read<http.Client>(),
              auth: FirebaseAuth.instance,
              session: widget.authService,
              store: FirestoreDirectAiStore(FirebaseFirestore.instance),
            ),
          ),
          RepositoryProvider<ProfileService>(
            create: (context) => FirestoreProfileService(
              store: context.read<FirestoreUserStore>(),
              catalog: context.read<MockApiClient>(),
              favorites: context.read<RecipeFavoritesService>(),
              published: context.read<PublishedRecipeSource>(),
              avatarPicker: ImagePickerRecipeCoverPicker(),
              avatarUploader: CloudinaryRecipeImageUploader(
                context.read<http.Client>(),
                uploadTag: 'bep_xinh_avatar',
              ),
            ),
            dispose: (service) => unawaited(service.dispose()),
          ),
          RepositoryProvider<PublicProfileService>(
            create: (context) => PublishedPublicProfileService(
              bundled: context.read<MockProfileService>(),
              source: context.read<PublishedRecipeSource>(),
              favorites: context.read<RecipeFavoritesService>(),
            ),
          ),
          RepositoryProvider<RecipeSearchService>(
            create: (context) => MockRecipeSearchService(
              context.read<MockApiClient>(),
              context.read<IngredientCatalogService>(),
              context.read<RecipeFavoritesService>(),
              published: context.read<PublishedRecipeSource>(),
            ),
          ),
          RepositoryProvider<SearchHistoryRepository>(
            create: (_) =>
                LocalSearchHistoryRepository.forUser(widget.authService.userId),
          ),
          RepositoryProvider<HomeService>(
            create: (context) => MockHomeService(
              context.read<MockApiClient>(),
              context.read<FridgeService>(),
              context.read<RecipeFavoritesService>(),
              published: context.read<PublishedRecipeSource>(),
            ),
          ),
          RepositoryProvider<RecipeImageUploader>(
            create: (context) =>
                CloudinaryRecipeImageUploader(context.read<http.Client>()),
          ),
          RepositoryProvider<RecipeSubmissionService>(
            create: (context) => FirestoreRecipeSubmissionService(
              context.read<FirestoreUserStore>(),
              context.read<IngredientCatalogService>(),
            ),
          ),
          RepositoryProvider<RecipeEditorService>(
            create: (context) => FirestoreRecipeEditorService(
              repository: FirestoreRecipeAuthoringRepository(
                context.read<FirestoreUserStore>(),
              ),
              uploader: context.read<RecipeImageUploader>(),
              catalog: context.read<IngredientCatalogService>(),
            ),
            dispose: (service) {
              if (service is RecipeEditorProgressSource) {
                unawaited((service as RecipeEditorProgressSource).dispose());
              }
            },
          ),
          RepositoryProvider<RecipeCoverPicker>(
            create: (_) => ImagePickerRecipeCoverPicker(),
          ),
          RepositoryProvider<ChatImageService>(
            create: (context) => DefaultChatImageService(
              picker: context.read<RecipeCoverPicker>(),
              uploader: CloudinaryRecipeImageUploader(
                context.read<http.Client>(),
                uploadTag: 'bep_xinh_chat',
              ),
            ),
          ),
        ],
        child: AiChatSessionScope(
          child: KitchenSessionHost(
            child: HomeUnreadScope(
              enabled: widget.authService.userId != null,
              child: BlocProvider.value(
                value: _theme,
                child: BlocBuilder<AppThemeCubit, ThemeMode>(
                  builder: (context, mode) => MaterialApp.router(
                    routerConfig: _router,
                    title: AppConstants.appName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: mode,
                    locale: DevicePreview.locale(context),
                    builder: (context, child) {
                      // Tích hợp responsive_framework cho toàn bộ ứng dụng
                      final responsiveChild = ResponsiveBreakpoints.builder(
                        child: child ?? const SizedBox.shrink(),
                        breakpoints: const [
                          Breakpoint(start: 0, end: 599, name: MOBILE),
                          Breakpoint(start: 600, end: 1024, name: TABLET),
                          Breakpoint(start: 1025, end: 1920, name: DESKTOP),
                          Breakpoint(
                            start: 1921,
                            end: double.infinity,
                            name: '4K',
                          ),
                        ],
                      );
                      return AppTheme.builder(context, responsiveChild);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
