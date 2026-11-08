import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../help/presentation/feature_walkthrough.dart';
import '../../../../shared/widgets/icon_bubble.dart';

class AdhdToolCard extends StatelessWidget {
  const AdhdToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.tourId,
    super.key,
  });

  final String? tourId;
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sage),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconBubble(icon: icon, color: AppColors.violet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (tourId != null)
            TourTarget(
              id: tourId!,
              child: FilledButton(onPressed: onTap, child: Text(action)),
            )
          else
            FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
