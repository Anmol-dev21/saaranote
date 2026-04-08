import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_colors.dart';
import '../viewmodels/note_viewmodel.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_all_notes_usecase.dart';
import 'add_note_screen.dart';
import 'ai_chat_screen.dart';
import 'library_screen.dart';
import 'note_editor_screen.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';

/// Home screen displaying the list of notes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load notes when screen initializes
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SaaraNote'),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context),
                AppSpacing.vGapSm,
                Consumer<NoteViewModel>(
                  builder: (context, viewModel, _) => _buildFilterChips(
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
                  return AppEmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'No notes yet',
                    message: 'Tap the + button to create your first note',
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
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'editor',
            mini: true,
            onPressed: () => _navigateToNoteEditor(context),
            tooltip: 'New Note (Rich Text & Drawing)',
            child: const Icon(Icons.draw),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _navigateToAddNote(context),
            tooltip: 'Quick Add (OCR/PDF)',
            icon: const Icon(Icons.add),
            label: const Text('New Note'),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return AppSearchBar(
      controller: _searchController,
      hintText: 'Search notes, topics, keywords',
      onChanged: _onSearchChanged,
      onClear: () => _onSearchChanged(''),
    );
  }

  Widget _buildFilterChips(BuildContext context, NoteViewModel viewModel) {
    final sort = viewModel.currentSort;
    final filterLabel = _filterLabel(viewModel.currentFilter);

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
            label: 'Type: $filterLabel',
            selected: true,
            onTap: () => _showTypeFilterSheet(context, viewModel),
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
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) return;
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
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon')),
        );
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

  void _showTypeFilterSheet(BuildContext context, NoteViewModel viewModel) {
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
                Text('Filter notes', style: Theme.of(context).textTheme.titleMedium),
                AppSpacing.vGapMd,
                _buildFilterOption(context, viewModel, NoteFilter.active, 'Active'),
                _buildFilterOption(context, viewModel, NoteFilter.all, 'All'),
                _buildFilterOption(context, viewModel, NoteFilter.archived, 'Archived'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    NoteViewModel viewModel,
    NoteFilter filter,
    String label,
  ) {
    final selected = viewModel.currentFilter == filter;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        viewModel.setFilter(filter);
      },
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

  void _navigateToAddNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNoteScreen()),
    ).then((created) {
      if (created == true) {
        context.read<NoteViewModel>().refresh();
      }
    });
  }

  void _navigateToNoteEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
    ).then((_) {
      context.read<NoteViewModel>().refresh();
    });
  }

  void _navigateToDetail(BuildContext context, int noteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(noteId: noteId),
      ),
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

  String _filterLabel(NoteFilter filter) {
    switch (filter) {
      case NoteFilter.active:
        return 'Active';
      case NoteFilter.all:
        return 'All';
      case NoteFilter.archived:
        return 'Archived';
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
