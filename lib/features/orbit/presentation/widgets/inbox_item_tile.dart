import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class InboxItemTile extends StatelessWidget {
  const InboxItemTile({
    required this.title,
    required this.onArchive,
    super.key,
  });

  final String title;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator_rounded, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_rounded),
              color: AppColors.primary,
              tooltip: 'Archive',
            ),
          ],
        ),
      ),
    );
  }
}
