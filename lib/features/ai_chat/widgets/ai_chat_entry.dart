import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../messages/models/conversation.dart';
import '../../messages/widgets/conversation_tile.dart';

const aiAvatarAsset = 'assets/images/bep_xinh_ai.png';

class AiChatEntry extends StatelessWidget {
  const AiChatEntry({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
    child: ConversationTile(
      conversation: const Conversation(
        id: 'ai',
        name: 'Bếp Xinh AI',
        subtitle: 'Trợ lý nấu ăn',
        messages: [],
      ),
      avatarAsset: aiAvatarAsset,
      emptyPreview: 'Gợi ý món ăn · Hướng dẫn dùng app',
      pinned: true,
      onOpen: () => context.push('/messages/ai'),
    ),
  );
}
