import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_report_cubit.dart';
import '../services/recipe_report_repository.dart';

Future<void> showRecipeReportDialog(
  BuildContext context,
  RecipeReportRepository repository,
  String recipeId,
) => showDialog<void>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => RecipeReportCubit(repository, recipeId)..load(),
    child: const RecipeReportDialog(),
  ),
);

class RecipeReportDialog extends StatefulWidget {
  const RecipeReportDialog({super.key});
  @override
  State<RecipeReportDialog> createState() => _RecipeReportDialogState();
}

class _RecipeReportDialogState extends State<RecipeReportDialog> {
  final reason = TextEditingController();
  String category = 'unsafe';
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeReportCubit, RecipeReportState>(
        builder: (context, state) {
          final cubit = context.read<RecipeReportCubit>();
          return PopScope(
            canPop: !state.busy,
            child: AlertDialog(
              title: const Text('Báo cáo món'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.loading)
                        const LinearProgressIndicator()
                      else if (state.report != null) ...[
                        const Text(
                          'Bạn đã báo cáo món này. Cảm ơn bạn đã giúp cộng đồng an toàn hơn.',
                        ),
                        const SizedBox(height: 12),
                        Text(switch (state.report!.status) {
                          'open' => 'Trạng thái: Chờ xử lý',
                          'dismissed' =>
                            'Trạng thái: Đã xem xét — không vi phạm',
                          _ => 'Trạng thái: Đã xử lý',
                        }),
                      ] else ...[
                        const Text(
                          'Chọn vấn đề bạn gặp. Admin sẽ xem xét trước khi quyết định xử lý.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Loại báo cáo',
                          ),
                          items: recipeReportCategories.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value, maxLines: 2),
                                ),
                              )
                              .toList(),
                          onChanged: state.busy
                              ? null
                              : (value) => setState(() => category = value!),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reason,
                          maxLength: 500,
                          minLines: 3,
                          maxLines: 5,
                          enabled: !state.busy,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Lý do báo cáo',
                            hintText: 'Mô tả cụ thể vấn đề bạn nhận thấy',
                          ),
                        ),
                        if (state.busy) const LinearProgressIndicator(),
                      ],
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: state.busy ? null : () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                if (!state.loading && state.report == null)
                  TextButton(
                    onPressed: state.busy || reason.text.trim().isEmpty
                        ? null
                        : () => cubit.submit(category, reason.text),
                    child: const Text('Gửi báo cáo'),
                  ),
              ],
            ),
          );
        },
      );
}
