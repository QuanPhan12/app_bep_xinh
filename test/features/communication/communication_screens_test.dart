import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';

import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_editor_fakes.dart';

import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/messages/widgets/chat_recipe_card.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/core/widgets/app_unread_indicator.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/home/widgets/home_unread_scope.dart';
import 'package:app_bep_xinh/features/notifications/services/notification_repository.dart';
import 'package:app_bep_xinh/features/notifications/screens/notifications_screen.dart';
import 'package:app_bep_xinh/features/messages/services/message_repository.dart';
import 'package:app_bep_xinh/features/messages/services/chat_image_service.dart';
import 'package:app_bep_xinh/features/messages/widgets/chat_attachment_preview.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_image_view.dart';
import 'package:app_bep_xinh/features/messages/screens/messages_screen.dart';
import 'package:app_bep_xinh/features/messages/screens/conversation_screen.dart';
import 'package:app_bep_xinh/features/navigation/widgets/app_bottom_nav_bar.dart';

import '../../support/communication_fakes.dart';
import '../../support/auth_fake.dart';
import '../../support/mock_services.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  setUp(() {
    configureAuthenticatedTaps();
    AppTapHandler.resetLock();
  });
  late FakeMessageRepository messages;
  late FakeNotificationRepository notifications;
  late FakeChatImageService images;
  setUp(() {
    messages = FakeMessageRepository();
    notifications = FakeNotificationRepository();
    images = FakeChatImageService();
  });
  tearDown(() async {
    await messages.dispose();
    await notifications.dispose();
  });

  Future<GoRouter> open(
    WidgetTester tester,
    String location, {
    double width = 390,
    double height = 900,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: location,
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      AppMessenger.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RecipeDetailService>(
            create: (_) =>
                StubRecipeDetailService()
                  ..onFetch = (id) async => RecipeDetailData(
                    recipe: RecipeDetail(
                      id: id,
                      author: detailFixture().author,
                      content: validRecipeDraft()
                          .copyWith(cover: messages.recipeOptions.first.cover)
                          .toRecipeContent(),
                    ),
                    isFavorite: false,
                    availableIngredientIds: {},
                  ),
          ),
          RepositoryProvider<RecipeFavoritesService>(
            create: (_) => StubRecipeFavoritesService(),
            dispose: (value) => value.dispose(),
          ),
          RepositoryProvider<MessageRepository>.value(value: messages),
          RepositoryProvider<ChatImageService>.value(value: images),
          RepositoryProvider<NotificationRepository>.value(
            value: notifications,
          ),
          RepositoryProvider<HomeService>(create: (_) => StubHomeService()),
        ],
        child: HomeUnreadScope(
          enabled: true,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(colorScheme: AppColors.lightColorScheme),
            builder: (context, child) => ResponsiveBreakpoints.builder(
              breakpoints: const [
                Breakpoint(start: 0, end: 599, name: MOBILE),
                Breakpoint(start: 600, end: double.infinity, name: TABLET),
              ],
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    AppTapHandler.resetLock();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  bool hasUnread(WidgetTester tester, String tooltip) => tester
      .widget<AppUnreadIndicator>(
        find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(AppUnreadIndicator),
        ),
      )
      .hasUnread;

  testWidgets(
    'recipe attachment sends a card with caption and opens the recipe',
    (tester) async {
      final route = await open(
        tester,
        PathRouter.conversation(FakeMessageRepository.conversationId),
      );
      await tester.enterText(
        find.byKey(const ValueKey('message_draft')),
        'Nấu món này nhé',
      );
      await tap(tester, find.byTooltip('Đính kèm'));
      await tap(tester, find.text('Chọn công thức'));
      expect(AppTapHandler.isBusy, false);
      await tester.enterText(
        find.byKey(const ValueKey('chat_recipe_search')),
        'trung',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Trứng chiên hành'));
      expect(find.byType(ChatRecipeCard), findsOneWidget);
      await tap(tester, find.byTooltip('Gửi tin nhắn'));
      expect(
        messages.thread.messages.last.recipe,
        messages.recipeOptions.first,
      );
      expect(messages.thread.messages.last.text, 'Nấu món này nhé');
      await tap(tester, find.text('Trứng chiên hành'));
      expect(
        route.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recipe/r_chat_recipe',
      );
      expect(AppTapHandler.isBusy, false);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(ChatRecipeCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 800.0]) {
    testWidgets(
      'recipe picker and preview fit width $width with keyboard and large text',
      (tester) async {
        await open(
          tester,
          PathRouter.conversation(FakeMessageRepository.conversationId),
          width: width,
          height: 850,
          scale: 1.5,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tap(tester, find.byTooltip('Đính kèm'));
        await tap(tester, find.text('Chọn công thức'));
        await tap(tester, find.text('Trứng chiên hành'));
        expect(find.byTooltip('Bỏ công thức đính kèm'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tap(tester, find.byTooltip('Bỏ công thức đính kèm'));
        expect(find.byType(ChatRecipeCard), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'recipe picker retries without locking the app and cancel retains caption',
    (tester) async {
      messages.onRecipes = () => Future.error(StateError('offline'));
      await open(
        tester,
        PathRouter.conversation(FakeMessageRepository.conversationId),
      );
      await tester.enterText(
        find.byKey(const ValueKey('message_draft')),
        'Giữ lời nhắn',
      );
      await tap(tester, find.byTooltip('Đính kèm'));
      await tap(tester, find.text('Chọn công thức'));
      expect(
        find.text('Chưa tải được công thức. Vui lòng thử lại.'),
        findsOneWidget,
      );
      messages.onRecipes = null;
      await tap(tester, find.text('Thử lại'));
      expect(find.text('Trứng chiên hành'), findsOneWidget);
      await tap(tester, find.byTooltip('Đóng'));
      expect(find.byType(ChatRecipeCard), findsNothing);
      expect(find.text('Giữ lời nhắn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choose, preview, remove and send image-only with keyboard and large text',
    (tester) async {
      await open(
        tester,
        PathRouter.conversation(messages.thread.id),
        width: 320,
        scale: 1.5,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Đính kèm'));
      await tap(tester, find.text('Chọn ảnh'));
      expect(find.byType(ChatAttachmentPreview), findsOneWidget);
      expect(images.uploads, 0);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byTooltip('Bỏ ảnh'));
      expect(find.byType(ChatAttachmentPreview), findsNothing);
      await tap(tester, find.byTooltip('Đính kèm'));
      await tap(tester, find.text('Chọn ảnh'));
      await tap(tester, find.byTooltip('Gửi tin nhắn'));
      expect(images.uploads, 1);
      expect(messages.thread.messages.last.image, FakeChatImageService.remote);
      expect(messages.thread.messages.last.text, '');
      expect(find.byType(ChatAttachmentPreview), findsNothing);
      expect(find.byType(RecipeImageView), findsOneWidget);
      await tap(tester, find.byType(RecipeImageView));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.getSize(find.byType(InteractiveViewer)).width, 320);
      await tap(tester, find.byTooltip('Quay lại').last);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opening messages releases tap lock before retry and compose', (
    tester,
  ) async {
    await open(tester, '/home');
    // Không reset khóa giữa các tap: phải bắt được việc chờ Future của route
    // đến lúc pop, vốn làm mọi thao tác trên màn mới bị chặn.
    await tester.tap(find.byTooltip('Nhắn tin'));
    await tester.pumpAndSettle();
    expect(find.byType(MessagesScreen), findsOneWidget);
    expect(AppTapHandler.isBusy, isFalse);

    messages.inboxChanges.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.tap(find.text('Thử lại'));
    // Tap có bước haptic bất đồng bộ; đợi callback thực thi trước khi
    // kiểm tra kết quả tải, không tự giải phóng khóa trong test.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsNothing);
    expect(messages.cancellations, 1);
    expect(AppTapHandler.isBusy, isFalse);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
    await tester.pumpAndSettle();
    expect(find.text('Trò chuyện mới'), findsOneWidget);
    expect(AppTapHandler.isBusy, isFalse);
  });

  testWidgets('failed conversation creation shows feedback and can retry', (
    tester,
  ) async {
    final router = await open(tester, '/messages/new');
    final pending = Completer<void>();
    messages.onStart = () => pending.future;
    await tester.tap(find.text('Mai'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('permission-denied'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa tạo được cuộc trò chuyện. Bạn thử lại nhé.'),
      findsWidgets,
    );
    expect(router.routeInformationProvider.value.uri.path, '/messages/new');
    expect(AppTapHandler.isBusy, isFalse);
    messages.onStart = null;
    AppMessenger.hide();
    await tap(tester, find.text('Mai'));
    expect(find.byType(ConversationScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1024.0]) {
    testWidgets(
      'Home actions open child pages and back preserves Home at $width',
      (tester) async {
        await open(tester, '/home', width: width);
        expect(find.byTooltip('Thông báo'), findsOneWidget);
        expect(find.byTooltip('Nhắn tin'), findsOneWidget);
        expect(hasUnread(tester, 'Thông báo'), isTrue);
        expect(hasUnread(tester, 'Nhắn tin'), isTrue);
        await tap(tester, find.byTooltip('Thông báo'));
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(find.byType(AppBottomNavBar), findsNothing);
        await tap(tester, find.text('Công thức đã được duyệt'));
        expect(notifications.items.single.isRead, true);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        await tap(tester, find.byTooltip('Quay lại'));
        expect(hasUnread(tester, 'Thông báo'), isFalse);
        expect(hasUnread(tester, 'Nhắn tin'), isTrue);
        await tap(tester, find.byTooltip('Nhắn tin'));
        expect(find.byType(MessagesScreen), findsOneWidget);
        await tap(tester, find.text('Mai'));
        expect(find.byType(ConversationScreen), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('message_draft')),
          'Xin chào từ Home',
        );
        await tester.pump();
        await tap(tester, find.byTooltip('Gửi tin nhắn'));
        expect(find.text('Xin chào từ Home'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.descendant(
                  of: find.byKey(const ValueKey('message_draft')),
                  matching: find.byType(TextFormField),
                  matchRoot: true,
                ),
              )
              .initialValue,
          '',
        );
        expect(tester.takeException(), isNull);
        await tap(tester, find.byTooltip('Quay lại'));
        await tap(tester, find.byTooltip('Quay lại'));
        expect(hasUnread(tester, 'Thông báo'), isFalse);
        expect(hasUnread(tester, 'Nhắn tin'), isFalse);
      },
    );
  }

  for (final path in ['/notifications', '/messages', '/messages/new']) {
    testWidgets('$path fits narrow screen and large text', (tester) async {
      await open(tester, path, width: 320, scale: 1.5);
      expect(tester.takeException(), isNull);
      final content = find.byWidgetPredicate(
        (w) =>
            w is CustomScrollView && w.physics is! NeverScrollableScrollPhysics,
      );
      await tester.drag(content.first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'composer retains text and focus across typing, keyboard and failed send',
    (tester) async {
      await open(
        tester,
        PathRouter.conversation(messages.thread.id),
        width: 320,
        scale: 1.5,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('message_draft'));
      await tester.enterText(field, 'M');
      await tester.pump();
      expect(tester.testTextInput.isVisible, true);
      await tester.enterText(field, 'Món ngon\nCảm ơn bạn!');
      await tester.pump();
      messages.onSend = () => Future.error(StateError('offline'));
      await tap(tester, find.byTooltip('Gửi tin nhắn'));
      expect(find.text('Món ngon\nCảm ơn bạn!'), findsOneWidget);
      messages.onSend = null;
      await tap(tester, find.byTooltip('Gửi tin nhắn'));
      expect(messages.requestIds.first, messages.requestIds.last);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  test('new pages remain protected by auth redirect', () {
    final auth = StubAuthService();
    addTearDown(auth.dispose);
    for (final path in [
      '/notifications',
      '/messages',
      '/messages/new',
      PathRouter.conversation(messages.thread.id),
    ]) {
      final redirect = Uri.parse(authRedirect(auth, Uri.parse(path))!);
      expect(redirect.path, '/login');
      expect(redirect.queryParameters['from'], path);
      auth.id = 'active';
      expect(authRedirect(auth, Uri.parse(path)), isNull);
      auth.id = null;
    }
  });
}
