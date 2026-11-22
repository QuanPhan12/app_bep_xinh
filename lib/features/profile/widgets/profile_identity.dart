import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../models/profile_data.dart';

/// Chỉ hiển thị hồ sơ; màn cha cung cấp thao tác và điều hướng.
class ProfileIdentity extends StatelessWidget {
  final ProfileData data;
  final bool useJournalCount;
  final int? journalCount;
  final VoidCallback onEdit;
  final VoidCallback? onCreate;
  final VoidCallback onSelectRecipes;
  final VoidCallback onSelectSaved;
  final VoidCallback? onOpenJournal;
  const ProfileIdentity({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onSelectRecipes,
    required this.onSelectSaved,
    this.onCreate,
    this.onOpenJournal,
    this.useJournalCount = false,
    this.journalCount,
  });
  @override
  Widget build(BuildContext context) {
    final account = data.account;
    // Handle tự sinh từ UID là khóa kỹ thuật, không trình bày như username tự chọn.
    final showHandle =
        account.handle.isNotEmpty && account.handle != 'bep_${account.id}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(
                name: account.name,
                assetPath: account.avatarAsset,
                imageUrl: account.avatarUrl,
                size: 80,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Stat(
                        key: const ValueKey('profile_stat_recipes'),
                        value: data.ownRecipes.length,
                        label: 'Công thức',
                        onTap: onSelectRecipes,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        key: const ValueKey('profile_stat_saved'),
                        value: data.savedRecipes.length,
                        label: 'Đã lưu',
                        onTap: onSelectSaved,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        key: const ValueKey('profile_stat_journal'),
                        value: useJournalCount
                            ? journalCount
                            : account.cookedCount,
                        label: 'Đã nấu',
                        onTap: onOpenJournal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            account.name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '@${account.handle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.colors.textSecondary),
              ),
            ),
          if (account.showBio && account.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                account.bio,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(14) > 19;
              final width = onCreate == null || stack
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: width,
                    child: OutlinedButton(
                      onPressed: onEdit,
                      child: const Text(
                        'Chỉnh sửa hồ sơ',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (onCreate != null)
                    SizedBox(
                      width: width,
                      child: FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                        label: const Text('Đăng món'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int? value;
  final String label;
  final VoidCallback? onTap;
  const _Stat({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            children: [
              Text(
                value?.toString() ?? '—',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
