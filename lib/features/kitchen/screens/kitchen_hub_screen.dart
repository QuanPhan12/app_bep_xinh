import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/app_layout.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../../core/widgets/app_menu_group.dart';
import '../../../core/widgets/app_feature_tile.dart';
import '../../../core/widgets/app_adaptive_columns.dart';
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
          'Thực đơn tuần',
          'Sắp xếp món theo ngày và bữa ăn',
          PhosphorIconsRegular.calendarBlank,
          '/kitchen/meal-plan',
        ),
        item(
          'Nguyên liệu & hạn dùng',
          'Theo dõi số lượng và dùng trước khi hết hạn',
          PhosphorIconsRegular.package,
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
          PhosphorIconsRegular.bookmarkSimple,
          '/profile?tab=saved',
        ),
        item(
          'Bộ sưu tập',
          'Gom món theo sở thích và dịp đặc biệt',
          PhosphorIconsRegular.books,
          '/kitchen/collections',
        ),
        item(
          'Đã tải xuống',
          'Đọc lại công thức khi mất mạng',
          PhosphorIconsRegular.downloadSimple,
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
          PhosphorIconsRegular.timer,
          '/kitchen/timers',
        ),
        item(
          'Nhật ký nấu ăn',
          'Ghi nhớ kinh nghiệm cho lần nấu sau',
          PhosphorIconsRegular.notebook,
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
          PhosphorIconsRegular.users,
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const KitchenTodayOverview(),
                        AppAdaptiveColumns(
                          breakpoint: 620,
                          spacing: 24,
                          primary: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [prepare, cooking],
                          ),
                          secondary: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [recipes, community],
                          ),
                        ),
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
