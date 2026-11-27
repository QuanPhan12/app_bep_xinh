import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/app_layout.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../../core/widgets/app_menu_group.dart';
import '../../../core/widgets/app_feature_tile.dart';
import '../../../sollume/core/theme/app_theme.dart';
import '../widgets/kitchen_today_overview.dart';

class KitchenHubScreen extends StatelessWidget {
  final bool embedded;
  const KitchenHubScreen({super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) {
    Widget item(String title, String subtitle, IconData icon, String route) =>
        AppFeatureTile(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: () => context.push(route),
        );
    final prepare = AppMenuGroup(
      title: 'Chuẩn bị bữa ăn',
      children: [
        item(
          'Ước tính calo',
          'Từ ảnh, công thức và bữa ăn của bạn',
          PhosphorIconsBold.calculator,
          '/kitchen/nutrition',
        ),
        item(
          'Thực đơn tuần',
          'Sắp xếp món theo ngày và bữa ăn',
          PhosphorIconsBold.calendarBlank,
          '/kitchen/meal-plan',
        ),
        item(
          'Nguyên liệu & hạn dùng',
          'Theo dõi số lượng và dùng trước khi hết hạn',
          PhosphorIconsBold.package,
          '/kitchen/pantry',
        ),
      ],
    );
    final recipes = AppMenuGroup(
      title: 'Công thức của bạn',
      children: [
        item(
          'Món đã lưu',
          'Các công thức bạn muốn nấu lại',
          PhosphorIconsBold.bookmarkSimple,
          '/profile?tab=saved',
        ),
        item(
          'Bộ sưu tập',
          'Gom món theo sở thích và dịp đặc biệt',
          PhosphorIconsBold.books,
          '/kitchen/collections',
        ),
        item(
          'Đã tải xuống',
          'Đọc lại công thức khi mất mạng',
          PhosphorIconsBold.downloadSimple,
          '/kitchen/offline',
        ),
      ],
    );
    final cooking = AppMenuGroup(
      title: 'Nấu và ghi nhớ',
      children: [
        item(
          'Hẹn giờ nấu',
          'Theo dõi thời gian cho từng bước',
          PhosphorIconsBold.timer,
          '/kitchen/timers',
        ),
        item(
          'Nhật ký nấu ăn',
          'Ghi nhớ kinh nghiệm cho lần nấu sau',
          PhosphorIconsBold.notebook,
          '/kitchen/journal',
        ),
      ],
    );
    final community = AppMenuGroup(
      title: 'Cộng đồng',
      children: [
        item(
          'Tác giả đang theo dõi',
          'Tìm lại tác giả và công thức của họ',
          PhosphorIconsBold.users,
          '/kitchen/following',
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
            child: CustomScrollView(
              slivers: [
                if (embedded)
                  const AppSliverAppBar.tab(title: 'Bếp của tôi')
                else
                  AppSliverAppBar(
                    title: 'Bếp của tôi',
                    onBackPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/profile'),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.gutter(MediaQuery.sizeOf(context).width),
                    AppSpacing.resolve(context, AppSpacing.xxl),
                    AppSizes.gutter(MediaQuery.sizeOf(context).width),
                    AppSpacing.resolve(context, AppSpacing.xl),
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const KitchenTodayOverview(),
                        prepare,
                        cooking,
                        recipes,
                        community,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
