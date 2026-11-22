import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_feature_theme.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../../core/widgets/app_messenger.dart';
import '../cubits/conversation_cubit.dart';
import '../services/message_repository.dart';
import '../services/chat_image_service.dart';
import '../widgets/conversation_content.dart';

class ConversationScreen extends StatelessWidget {
  final String id;
  const ConversationScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(id),
    create: (context) => ConversationCubit(
      id: id,
      repository: context.read<MessageRepository>(),
      images: context.read<ChatImageService>(),
    )..load(),
    child: const AppFeatureTheme(child: _ConversationPage()),
  );
}

class _ConversationPage extends StatelessWidget {
  const _ConversationPage();
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ConversationCubit, ConversationState>(
        listenWhen: (previous, next) =>
            next.error != null &&
            previous.error != next.error &&
            next.conversation != null,
        listener: (context, state) =>
            AppMessenger.showError(context, state.error!),
        builder: (context, state) => AppPageScaffold(
          appBar: AppSliverAppBar(
            title: 'Trò chuyện',
            actions: state.error == null
                ? null
                : [
                    IconButton(
                      tooltip: 'Kết nối lại',
                      onPressed: context.read<ConversationCubit>().load,
                      icon: const Icon(PhosphorIconsRegular.arrowClockwise),
                    ),
                  ],
            onBackPressed: () => context.canPop()
                ? context.pop()
                : context.go(PathRouter.messagesScreen),
          ),
          body: const ConversationContent(),
        ),
      );
}
