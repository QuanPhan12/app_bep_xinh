import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../screens/messages_screen.dart';
import '../screens/new_message_screen.dart';
import '../screens/conversation_screen.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';

List<RouteBase> messageRoutes() => [
  GoRoute(path: '/messages/ai', builder: (_, _) => const AiChatScreen()),
  GoRoute(
    path: PathRouter.messagesScreen,
    builder: (_, _) => const MessagesScreen(),
  ),
  GoRoute(
    path: PathRouter.newMessageScreen,
    builder: (_, _) => const NewMessageScreen(),
  ),
  GoRoute(
    path: '${PathRouter.messagesScreen}/:id',
    builder: (_, state) => ConversationScreen(id: state.pathParameters['id']!),
  ),
];
