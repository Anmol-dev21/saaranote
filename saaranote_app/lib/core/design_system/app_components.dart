import 'package:flutter/material.dart';
import 'app_spacing.dart';

/// SaaraNote Reusable UI Components
/// Based on design system specifications

/// Modern card widget with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool showBorder;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: padding ?? AppSpacing.cardContentPadding,
      child: child,
    );

    if (onTap != null) {
      return Card(
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          child: cardContent,
        ),
      );
    }

    return Card(
      color: color,
      child: cardContent,
    );
  }
}

/// Compact card for list items
class AppListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppListCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.paddingMd,
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              AppSpacing.hGapMd,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    AppSpacing.vGapXs,
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              AppSpacing.hGapMd,
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget with icon and message
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            AppSpacing.vGapLg,
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.vGapSm,
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              AppSpacing.vGapLg,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading indicator with optional message
class AppLoadingIndicator extends StatelessWidget {
  final String? message;

  const AppLoadingIndicator({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            AppSpacing.vGapMd,
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header with title and optional action
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const AppSectionHeader({
    Key? key,
    required this.title,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.verticalMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Chip with consistent styling
class AppChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool selected;

  const AppChip({
    Key? key,
    required this.label,
    this.onDeleted,
    this.onTap,
    this.backgroundColor,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap?.call(),
        backgroundColor: backgroundColor,
        deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 16) : null,
        onDeleted: onDeleted,
      );
    }

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 16) : null,
      onDeleted: onDeleted,
    );
  }
}

/// Search bar with consistent styling
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchBar({
    Key? key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

/// Info banner for messages and alerts
class AppInfoBanner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onDismiss;

  const AppInfoBanner({
    Key? key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor ?? theme.colorScheme.onPrimaryContainer,
              size: AppSpacing.iconMd,
            ),
            AppSpacing.hGapMd,
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor ?? theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            AppSpacing.hGapMd,
            IconButton(
              icon: Icon(
                Icons.close,
                size: AppSpacing.iconMd,
                color: textColor ?? theme.colorScheme.onPrimaryContainer,
              ),
              onPressed: onDismiss,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
