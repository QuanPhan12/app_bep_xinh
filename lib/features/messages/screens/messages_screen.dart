import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_feature_theme.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../cubits/messages_cubit.dart';
import '../services/message_repository.dart';
import '../widgets/messages_content.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        MessagesCubit(context.read<MessageRepository>())..load(),
    child: const AppFeatureTheme(child: _MessagesPage()),
  );
}

class _MessagesPage extends StatelessWidget {
  const _MessagesPage();
  @override
  Widget build(BuildContext context) => AppPageScaffold(
    appBar: AppSliverAppBar(
      title: 'Nhắn tin',
      onBackPressed: () =>
          context.canPop() ? context.pop() : context.go(PathRouter.homeScreen),
      actions: [
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          icon: const Icon(PhosphorIconsRegular.notePencil),
          onPressed: context.onAppTap(() {
            context.push(PathRouter.newMessageScreen);
          }, actionName: 'messages_compose'),
        ),
      ],
    ),
    body: MessagesContent(
      onOpen: (id) {
        context.push(PathRouter.conversation(id));
      },
    ),
  );
}
