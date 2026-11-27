import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../kitchen/services/kitchen_services.dart';
import '../../recipe_reviews/services/recipe_review_repository.dart';
import 'post_action.dart';

class _CommentCountCubit extends Cubit<int?> {
  _CommentCountCubit(RecipeReviewRepository repository, String recipeId)
    : super(null) {
    _subscription = repository
        .ratings(recipeId)
        .listen(
          (summary) {
            if (!isClosed) {
              emit(summary.count);
            }
          },
          onError: (Object _) {
            // Giữ số đã biết; nếu chưa có dữ liệu thì UI hiện dấu — thay vì số 0 giả.
          },
        );
  }
  late final StreamSubscription<RatingSummary> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}

class PostCommentAction extends StatelessWidget {
  const PostCommentAction({
    super.key,
    required this.recipeId,
    required this.fallbackCount,
    this.onPressed,
  });
  final String recipeId;
  final int fallbackCount;
  final VoidCallback? onPressed;
  Widget _action(int? count) => PostAction(
    count: count,
    unit: 'đánh giá đã duyệt',
    tooltip: 'Đánh giá cộng đồng',
    onPressed: onPressed,
    icon: PhosphorIconsRegular.chatCircle,
  );
  @override
  Widget build(BuildContext context) {
    final services = KitchenScope.maybeOf(context);
    if (services == null || !recipeId.startsWith('r_')) {
      return _action(fallbackCount);
    }
    return BlocProvider(
      key: ValueKey(recipeId),
      create: (_) => _CommentCountCubit(services.reviews, recipeId),
      child: BlocBuilder<_CommentCountCubit, int?>(
        builder: (_, count) => _action(count),
      ),
    );
  }
}
