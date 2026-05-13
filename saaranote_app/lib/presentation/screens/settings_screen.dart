import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'ai_chat_screen.dart';
import 'library_screen.dart';
import 'debug_tools_screen.dart';

/// Settings screen for profile and preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          if (!settings.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInfoBanner(
                  message: 'Preferences stay offline until cloud sync is ready.',
                  icon: Icons.lock_outline,
                ),
                if (settings.hasError) ...[
                  AppSpacing.vGapSm,
                  AppInfoBanner(
                    message: settings.errorMessage ?? 'Settings failed to load.',
                    icon: Icons.error_outline,
                    backgroundColor: theme.colorScheme.errorContainer,
                    textColor: theme.colorScheme.onErrorContainer,
                  ),
                ],
                AppSpacing.vGapLg,
                _buildProfileCard(context),
                AppSpacing.vGapLg,
                const AppSectionHeader(title: 'Appearance'),
                _buildSettingsGroup(
                  context,
                  tiles: [
                    _buildActionTile(
                      context,
                      icon: Icons.light_mode_outlined,
                      title: 'Theme',
                      subtitle: 'Light, dark, or system default',
                      valueLabel: _themeModeLabel(settings.themeMode),
                      onTap: () => _showThemeSheet(context, settings),
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.format_size,
                      title: 'Text size',
                      subtitle: 'Optimize reading comfort',
                      valueLabel: _textScaleLabel(settings.textScale),
                      onTap: () => _showTextScaleSheet(context, settings),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Accent color',
                      subtitle: 'Personalize your highlights',
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                const AppSectionHeader(title: 'AI Features'),
                _buildSettingsGroup(
                  context,
                  tiles: [
                    _buildToggleTile(
                      context,
                      icon: Icons.smart_toy_outlined,
                      title: 'Offline chat',
                      subtitle: 'Ask questions without the cloud',
                      value: settings.offlineChatEnabled,
                      onChanged: settings.setOfflineChatEnabled,
                    ),
                    _buildToggleTile(
                      context,
                      icon: Icons.summarize_outlined,
                      title: 'Auto summaries',
                      subtitle: 'Generate quick overviews',
                      value: settings.autoSummariesEnabled,
                      onChanged: settings.setAutoSummariesEnabled,
                    ),
                    _buildToggleTile(
                      context,
                      icon: Icons.style_outlined,
                      title: 'Flashcards',
                      subtitle: 'Turn notes into study cards',
                      value: settings.flashcardsEnabled,
                      onChanged: settings.setFlashcardsEnabled,
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                const AppSectionHeader(title: 'Storage & Data'),
                _buildSettingsGroup(
                  context,
                  tiles: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.storage_outlined,
                      title: 'Local storage',
                      subtitle: 'Manage cached files',
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.file_download_outlined,
                      title: 'Export data',
                      subtitle: 'Download notes and summaries',
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.security_outlined,
                      title: 'Data safety',
                      subtitle: 'Review offline backups',
                    ),
                  ],
                ),
                AppSpacing.vGapLg,
                const AppSectionHeader(title: 'Support'),
                _buildSettingsGroup(
                  context,
                  tiles: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & feedback',
                      subtitle: 'Guides and contact options',
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Licenses',
                      subtitle: 'Open-source acknowledgements',
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'About SaaraNote',
                      subtitle: 'Version, build, and credits',
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  AppSpacing.vGapLg,
                  const AppSectionHeader(title: 'Developer'),
                  _buildSettingsGroup(
                    context,
                    tiles: [
                      _buildNavigationTile(
                        context,
                        icon: Icons.bug_report_outlined,
                        title: 'Debug tools',
                        subtitle: 'OCR, indexing, and retrieval diagnostics',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DebugToolsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AppSpacing.vGapXl,
                Center(
                  child: Text(
                    'SaaraNote v2.0',
                    style: AppTypography.bodySmall(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'SN',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SaaraNote Profile',
                  style: theme.textTheme.titleMedium,
                ),
                AppSpacing.vGapXs,
                Text(
                  'Offline workspace',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Profile details',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required List<Widget> tiles,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(tiles.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            );
          }
          return tiles[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showComingSoon(context),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String valueLabel,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        valueLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  void _showThemeSheet(BuildContext context, SettingsViewModel settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vGapMd,
                _buildThemeOption(context, settings, ThemeMode.system, 'System default'),
                _buildThemeOption(context, settings, ThemeMode.light, 'Light'),
                _buildThemeOption(context, settings, ThemeMode.dark, 'Dark'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    SettingsViewModel settings,
    ThemeMode mode,
    String label,
  ) {
    final selected = settings.themeMode == mode;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () {
        settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showTextScaleSheet(BuildContext context, SettingsViewModel settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Text size', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vGapMd,
                _buildTextScaleOption(context, settings, 0.9, 'Small'),
                _buildTextScaleOption(context, settings, 1.0, 'Default'),
                _buildTextScaleOption(context, settings, 1.1, 'Large'),
                _buildTextScaleOption(context, settings, 1.2, 'Extra large'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextScaleOption(
    BuildContext context,
    SettingsViewModel settings,
    double value,
    String label,
  ) {
    final selected = settings.textScale == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () {
        settings.setTextScale(value);
        Navigator.pop(context);
      },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _textScaleLabel(double value) {
    if (value <= 0.9) return 'Small';
    if (value <= 1.0) return 'Default';
    if (value <= 1.1) return 'Large';
    return 'Extra large';
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {
        if (index == 3) return;
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
          return;
        }
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LibraryScreen()),
          );
          return;
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatScreen()),
          );
          return;
        }
        _showComingSoon(context);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}
