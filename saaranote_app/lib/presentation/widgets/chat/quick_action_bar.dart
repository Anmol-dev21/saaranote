import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../viewmodels/chat_viewmodel.dart';

/// Quick action bar with one-tap commands
class QuickActionBar extends StatelessWidget {
  final Function(QuickAction) onAction;
  final bool isLoading;

  const QuickActionBar({
    super.key,
    required this.onAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickActionChip(
              icon: Icons.summarize_outlined,
              label: 'Summarize',
              onTap: isLoading ? null : () => onAction(QuickAction.summarize),
            ),
            AppSpacing.hGapSm,
            _QuickActionChip(
              icon: Icons.format_list_bulleted,
              label: 'Key Points',
              onTap: isLoading
                  ? null
                  : () => onAction(QuickAction.extractKeyPoints),
            ),
            AppSpacing.hGapSm,
            _QuickActionChip(
              icon: Icons.quiz_outlined,
              label: 'Flashcards',
              onTap: isLoading
                  ? null
                  : () => onAction(QuickAction.generateFlashcards),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual quick action chip
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isEnabled
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isEnabled
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
