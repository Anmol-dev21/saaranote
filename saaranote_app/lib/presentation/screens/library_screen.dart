import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_colors.dart';
import '../viewmodels/note_viewmodel.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_all_notes_usecase.dart';
import 'ai_chat_screen.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';

/// Library screen showing all notes, folders, and tags
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteViewModel>().fetchNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<NoteViewModel>().searchNotes(query);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Library'),
            ),
            body: Column(
              children: [
                _buildTabStrip(context),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAllNotesTab(),
                      _buildFoldersTab(context),
                      _buildTagsTab(context),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
                    animation: tabController,
                    builder: (context, child) {
                      if (tabController.index != 1) {
                        return const SizedBox.shrink();
                      }

                      return FloatingActionButton.extended(
                        onPressed: () => _showComingSoon(context),
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('New Folder'),
                      );
                    },
                  ),
            bottomNavigationBar: _buildBottomNav(context),
          );
        },
      ),
    );
  }

  Widget _buildTabStrip(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'All Notes'),
            Tab(text: 'Folders'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotesTab() {
    return Column(
      children: [
        Padding(
          padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search titles and content',
                onChanged: _onSearchChanged,
                onClear: () => _onSearchChanged(''),
              ),
              AppSpacing.vGapSm,
              Consumer<NoteViewModel>(
                builder: (context, viewModel, _) => _buildSortChips(
                  context,
                  viewModel,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<NoteViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const AppLoadingIndicator(message: 'Loading notes...');
              }

              if (viewModel.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Oops!',
                  message: viewModel.errorMessage ?? 'An error occurred',
                  action: ElevatedButton.icon(
                    onPressed: () => viewModel.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                );
              }

              if (!viewModel.hasNotes) {
                return const AppEmptyState(
                  icon: Icons.note_add_outlined,
                  title: 'No notes yet',
                  message: 'Create a note to start building your library.',
                );
              }

              return RefreshIndicator(
                onRefresh: () => viewModel.refresh(),
                child: ListView.builder(
                  itemCount: viewModel.noteCount,
                  padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
                  itemBuilder: (context, index) {
                    final note = viewModel.notes[index];
                    return Padding(
                      padding: AppSpacing.verticalSm,
                      child: _buildNoteCard(context, note, viewModel),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoldersTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoBanner(
            message: 'Folders are coming soon. Use search and tags to stay organized.',
            icon: Icons.folder_open,
          ),
          AppSpacing.vGapLg,
          AppSectionHeader(
            title: 'Get started',
            action: TextButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Create folder'),
            ),
          ),
          AppCard(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_special_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build a structure that fits your flow',
                        style: theme.textTheme.titleMedium,
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Group related notes and keep your library tidy.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapLg,
          const AppSectionHeader(title: 'Suggested structure'),
          _buildFolderSuggestion(
            context,
            icon: Icons.school_outlined,
            title: 'Courses',
            subtitle: 'Keep lectures, assignments, and reviews together.',
          ),
          AppSpacing.vGapSm,
          _buildFolderSuggestion(
            context,
            icon: Icons.work_outline,
            title: 'Projects',
            subtitle: 'Track planning, meeting notes, and deliverables.',
          ),
          AppSpacing.vGapSm,
          _buildFolderSuggestion(
            context,
            icon: Icons.psychology_outlined,
            title: 'Research',
            subtitle: 'Capture sources, summaries, and key ideas.',
          ),
          AppSpacing.vGapLg,
          const AppSectionHeader(title: 'Folder tips'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildInfoChip(
                context,
                label: 'Pin important folders',
                icon: Icons.push_pin_outlined,
              ),
              _buildInfoChip(
                context,
                label: 'Color-code topics',
                icon: Icons.palette_outlined,
              ),
              _buildInfoChip(
                context,
                label: 'Keep it lightweight',
                icon: Icons.tips_and_updates_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoBanner(
            message: 'Tags are arriving soon. Use them to group themes across folders.',
            icon: Icons.sell_outlined,
          ),
          AppSpacing.vGapLg,
          AppSectionHeader(
            title: 'Suggested tags',
            action: TextButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create tag'),
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildTagChip(context, label: 'Exam prep'),
              _buildTagChip(context, label: 'Meetings'),
              _buildTagChip(context, label: 'Reading list'),
              _buildTagChip(context, label: 'Ideas'),
              _buildTagChip(context, label: 'References'),
              _buildTagChip(context, label: 'To review'),
            ],
          ),
          AppSpacing.vGapLg,
          const AppSectionHeader(title: 'How tags help'),
          AppCard(
            padding: AppSpacing.paddingMd,
            child: Column(
              children: [
                _buildTagGuideItem(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Connect notes across folders',
                  subtitle: 'Link related topics without moving files around.',
                ),
                AppSpacing.vGapSm,
                _buildTagGuideItem(
                  context,
                  icon: Icons.filter_alt_outlined,
                  title: 'Filter your library fast',
                  subtitle: 'Jump to a topic with one tap.',
                ),
                AppSpacing.vGapSm,
                _buildTagGuideItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Surface AI highlights',
                  subtitle: 'Tags help summaries and flashcards stay grouped.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChips(BuildContext context, NoteViewModel viewModel) {
    final sort = viewModel.currentSort;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(
            label: 'Recent',
            selected: sort == NoteSortBy.createdDateDesc,
            onTap: () => viewModel.setSortBy(NoteSortBy.createdDateDesc),
          ),
          AppSpacing.hGapSm,
          AppChip(
            label: 'Oldest',
            selected: sort == NoteSortBy.createdDateAsc,
            onTap: () => viewModel.setSortBy(NoteSortBy.createdDateAsc),
          ),
          AppSpacing.hGapSm,
          AppChip(
            label: 'A-Z',
            selected: sort == NoteSortBy.titleAsc,
            onTap: () => viewModel.setSortBy(NoteSortBy.titleAsc),
          ),
          AppSpacing.hGapSm,
          AppChip(
            label: 'Pinned',
            selected: false,
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, NoteViewModel viewModel) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accent = note.color != null
        ? _parseColor(note.color!)
        : theme.colorScheme.primary;

    return Card(
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(context, note.id!),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.note_outlined, color: accent, size: 20),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      _buildNotePreview(note.content),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vGapSm,
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        AppSpacing.hGapXs,
                        Text(
                          _formatDate(note.updatedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildNoteActions(context, note.id!, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        if (index == 0) {
          Navigator.maybePop(context);
          return;
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatScreen()),
          );
          return;
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
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

  Widget _buildNoteActions(BuildContext context, int noteId, NoteViewModel viewModel) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      iconSize: AppSpacing.iconMd,
      onPressed: () async {
        final value = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.of(context).size.width,
            kToolbarHeight,
            0,
            0,
          ),
          items: [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.errorLight, size: AppSpacing.iconMd),
                  AppSpacing.hGapSm,
                  Text('Delete', style: TextStyle(color: AppColors.errorLight)),
                ],
              ),
            ),
          ],
        );

        if (value == 'delete' && context.mounted) {
          final confirm = await _showDeleteConfirmation(context);
          if (confirm == true && context.mounted) {
            final success = await viewModel.deleteNote(noteId);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Note deleted'),
                  backgroundColor: AppColors.successLight,
                ),
              );
            }
          }
        }
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, int noteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(noteId: noteId),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Widget _buildFolderSuggestion(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.paddingMd,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                AppSpacing.vGapXs,
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showComingSoon(context),
            icon: const Icon(Icons.add),
            tooltip: 'Create folder',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          AppSpacing.hGapXs,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, {required String label}) {
    return AppChip(
      label: label,
      selected: false,
      onTap: () => _showComingSoon(context),
    );
  }

  Widget _buildTagGuideItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              AppSpacing.vGapXs,
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _buildNotePreview(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'No content yet';
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
