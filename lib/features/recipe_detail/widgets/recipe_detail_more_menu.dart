import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_messenger.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/cubits/recipe_tools_cubit.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/widgets/recipe_kitchen_actions.dart';
import '../../recipe_reports/widgets/recipe_report_dialog.dart';
import '../models/recipe_detail.dart';

enum _RecipeAction {
  save,
  remix,
  share,
  copy,
  meal,
  nutrition,
  collection,
  download,
  reviews,
  report,
}

class RecipeDetailMoreMenu extends StatelessWidget {
  const RecipeDetailMoreMenu({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.savingFavorite,
    required this.onToggleFavorite,
    this.isCooking = false,
    this.servings,
  });
  final RecipeDetail recipe;
  final bool isFavorite, savingFavorite, isCooking;
  final int? servings;
  final FutureOr<void> Function() onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final kitchen = KitchenScope.maybeOf(context);
    if (kitchen == null) return _menu(context, null, const RecipeToolsState());
    return BlocProvider(
      create: (_) => RecipeToolsCubit(kitchen),
      child: BlocConsumer<RecipeToolsCubit, RecipeToolsState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) {
          if (state.success) {
            AppMessenger.showSuccess(context, state.message!);
          } else {
            AppMessenger.showError(context, state.message!);
          }
        },
        builder: (context, state) => _menu(context, kitchen, state),
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    KitchenServices? kitchen,
    RecipeToolsState state,
  ) {
    final reports = kitchen?.reports;
    final canReport =
        reports != null &&
        recipe.id.startsWith('r_') &&
        recipe.author.id != null &&
        kitchen!.uid != recipe.author.id;
    final canRemix =
        !isCooking && recipe.id.startsWith('r_') && recipe.contentHash != null;
    PopupMenuItem<_RecipeAction> item(
      _RecipeAction action,
      String label,
      IconData icon, {
      bool enabled = true,
      Color? color,
    }) => PopupMenuItem(
      value: action,
      enabled: enabled && !state.busy,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
    return PopupMenuButton<_RecipeAction>(
      tooltip: 'Tùy chọn công thức',
      icon: const Icon(PhosphorIconsRegular.dotsThree),
      onSelected: (action) {
        if (state.busy ||
            (action == _RecipeAction.save && savingFavorite) ||
            (action == _RecipeAction.report && !canReport)) {
          return;
        }
        final tools = kitchen == null ? null : context.read<RecipeToolsCubit>();
        final FutureOr<void> Function() callback = switch (action) {
          _RecipeAction.save => onToggleFavorite,
          _RecipeAction.remix => () {
            context.push(
              '/recipes/new?remix=${Uri.encodeQueryComponent(recipe.id)}',
            );
          },
          _RecipeAction.report => () {
            unawaited(showRecipeReportDialog(context, reports!, recipe.id));
          },
          _RecipeAction.share => () {
            final box = context.findRenderObject() as RenderBox?;
            final origin = box == null
                ? const Rect.fromLTWH(0, 0, 1, 1)
                : box.localToGlobal(Offset.zero) & box.size;
            return tools!.share(recipe.id, origin);
          },
          _RecipeAction.copy => () => tools!.copy(recipe.id),
          // Mở form rồi nhả khóa tap; các nút bên trong form cần tiếp tục thao tác.
          _RecipeAction.meal => () {
            unawaited(
              showAddMealFromRecipe(
                context,
                RecipeRef.fromRecipe(recipe),
                servings ?? recipe.servings,
              ),
            );
          },
          _RecipeAction.nutrition => () {
            context.push(
              '/kitchen/nutrition?recipe=${Uri.encodeQueryComponent(recipe.id)}&servings=${servings ?? recipe.servings}',
            );
          },
          _RecipeAction.collection => () {
            unawaited(showRecipeCollectionChooser(context, recipe.id));
          },
          _RecipeAction.download => () => tools!.download(recipe),
          _RecipeAction.reviews => () {
            context.push('/recipe/${Uri.encodeComponent(recipe.id)}/reviews');
          },
        };
        context
            .onAppTap(
              callback,
              actionName: switch (action) {
                _RecipeAction.save => 'recipe_detail_favorite',
                _RecipeAction.remix => 'recipe_remix_start',
                _RecipeAction.report => 'recipe_report_open',
                _ => 'recipe_detail_${action.name}',
              },
              requiresAuth: !const {
                _RecipeAction.share,
                _RecipeAction.copy,
                _RecipeAction.reviews,
              }.contains(action),
            )
            ?.call();
      },
      itemBuilder: (_) => [
        item(
          _RecipeAction.save,
          savingFavorite
              ? 'Đang lưu…'
              : isFavorite
              ? 'Bỏ lưu món'
              : 'Lưu món',
          isFavorite
              ? PhosphorIconsFill.bookmark
              : PhosphorIconsRegular.bookmark,
          enabled: !savingFavorite,
          color: isFavorite ? Theme.of(context).colorScheme.primary : null,
        ),
        if (canRemix)
          item(
            _RecipeAction.remix,
            'Biến tấu công thức',
            PhosphorIconsRegular.arrowsClockwise,
          ),
        if (kitchen != null) ...[
          const PopupMenuDivider(),
          item(
            _RecipeAction.share,
            'Chia sẻ',
            PhosphorIconsRegular.shareNetwork,
          ),
          item(
            _RecipeAction.copy,
            'Sao chép liên kết',
            PhosphorIconsRegular.link,
          ),
          if (kitchen.signedIn) ...[
            item(
              _RecipeAction.nutrition,
              'Ước tính calo',
              Icons.calculate_outlined,
            ),
            item(
              _RecipeAction.meal,
              'Thêm vào thực đơn',
              PhosphorIconsRegular.calendarBlank,
            ),
            item(
              _RecipeAction.collection,
              'Bộ sưu tập',
              PhosphorIconsRegular.bookmarks,
            ),
            item(
              _RecipeAction.download,
              'Tải xuống',
              PhosphorIconsRegular.downloadSimple,
            ),
          ],
          if (recipe.id.startsWith('r_'))
            item(
              _RecipeAction.reviews,
              'Đánh giá cộng đồng',
              PhosphorIconsRegular.star,
            ),
        ],
        if (canReport) ...[
          const PopupMenuDivider(),
          item(_RecipeAction.report, 'Báo cáo món', PhosphorIconsRegular.flag),
        ],
      ],
    );
  }
}
