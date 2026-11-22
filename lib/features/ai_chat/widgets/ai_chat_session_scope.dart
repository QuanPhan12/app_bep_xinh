import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/ai_chat_cubit.dart';
import '../services/ai_chat_repository.dart';

/// Đặt trong scope UID của app: rời route không đóng AI, đổi tài khoản mới đóng.
class AiChatSessionScope extends StatelessWidget {
  final Widget child;
  const AiChatSessionScope({super.key, required this.child});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AiChatCubit(context.read<AiChatRepository>()),
    child: child,
  );
}
