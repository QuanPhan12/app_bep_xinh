import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:app_bep_xinh/core/widgets/app_page_scaffold.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);

  testWidgets('tab title hides down and reappears on reverse scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              const AppSliverAppBar.tab(title: 'Trang chủ'),
              AppSliverContent(
                maxWidth: 440,
                slivers: [
                  SliverList.builder(
                    itemCount: 60,
                    itemBuilder: (_, i) =>
                        SizedBox(height: 80, child: Text('Món $i')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final bar = find.byType(AppBar);
    final originalY = tester.getTopLeft(bar).dy;
    expect(
      tester.getSize(bar).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
    expect(find.byType(BackButton), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 90));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(bar).dy, originalY);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child header stays fixed while content scrolls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageScaffold(
          appBar: const AppSliverAppBar(title: 'Cài đặt'),
          body: AppContentScrollView(
            children: List.generate(
              60,
              (i) => SizedBox(height: 80, child: Text('Mục $i')),
            ),
          ),
          bottomNavigationBar: const SizedBox(height: 60, child: Text('Lưu')),
        ),
      ),
    );
    final originalY = tester.getTopLeft(find.byType(AppBar)).dy;
    final actionY = tester.getTopLeft(find.text('Lưu')).dy;
    await tester.drag(
      find.descendant(
        of: find.byType(AppContentScrollView),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(AppBar)).dy, originalY);
    expect(tester.getTopLeft(find.text('Lưu')).dy, actionY);
    expect(find.text('Mục 0').hitTestable(), findsNothing);
    await tester.ensureVisible(find.text('Mục 8'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Mục 8')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppBar)).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
