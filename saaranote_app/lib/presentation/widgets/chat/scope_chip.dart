import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';

/// Chip widget showing the current scope
class ScopeChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const ScopeChip({
    super.key,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        Chip(
          avatar: const Icon(Icons.filter_alt, size: 18),
          label: Text(label),
          onDeleted: onClear,
          deleteIcon: const Icon(Icons.close, size: 18),
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }
}
