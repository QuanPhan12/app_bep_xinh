import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_feature_theme.dart';
import '../../../core/widgets/app_inbox_components.dart';
import '../../../core/widgets/app_load_state.dart';
import '../cubits/recipients_cubit.dart';
import '../services/message_repository.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        RecipientsCubit(context.read<MessageRepository>())..load(),
    child: const AppFeatureTheme(child: _RecipientsPage()),
  );
}

class _RecipientsPage extends StatelessWidget {
  const _RecipientsPage();
  @override
  Widget build(BuildContext context) => AppPageScaffold(
    appBar: AppSliverAppBar(
      title: 'Trò chuyện mới',
      onBackPressed: () => context.canPop()
          ? context.pop()
          : context.go(PathRouter.messagesScreen),
    ),
    body: BlocConsumer<RecipientsCubit, RecipientsState>(
      listenWhen: (previous, next) =>
          previous.opening && !next.opening && next.error != null,
      listener: (context, state) =>
          AppMessenger.showError(context, state.error!),
      builder: (context, state) {
        final cubit = context.read<RecipientsCubit>();
        return AppInboxBody(
          children: [
            // const AppFeatureHeader(
            //   eyebrow: 'MỘT LỜI CHÀO',
            //   title: 'Gặp người cùng yêu bếp',
            //   description: 'Kết nối với những tác giả có công thức đã được duyệt trên Bếp Xinh.',
            // ),
            // const SizedBox(height: 20),
            AppSearchBar(
              hintText: 'Tìm tên tác giả',
              initialValue: state.query,
              onChanged: cubit.search,
              fieldKey: const ValueKey('recipient_search'),
            ),
            const SizedBox(height: 16),
            if (state.loading)
              const SizedBox(height: 240, child: AppLoadState(isLoading: true))
            else if (state.error != null)
              AppLoadState(message: state.error, onRetry: cubit.load),
            if (!state.loading &&
                state.error == null &&
                state.visibleItems.isEmpty)
              const AppInboxEmpty(
                icon: PhosphorIconsRegular.users,
                title: 'Chưa tìm thấy tác giả',
                description: 'Những người chia sẻ công thức đã duyệt sẽ xuất hiện ở đây.',
              ),
            for (final person in state.visibleItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: AppAvatar(name: person.name),
                      title: Text(person.name),
                      subtitle: const Text('Tác giả công thức'),
                      trailing: state.openingRecipientId == person.id
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(PhosphorIconsRegular.chatCircleDots),
                      onTap: state.opening
                          ? null
                          : context.onAppTap(() async {
                              final id = await cubit.start(person);
                              if (id != null && context.mounted) {
                                context.pushReplacement(
                                  PathRouter.conversation(id),
                                );
                              }
                            }, actionName: 'messages_start'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
