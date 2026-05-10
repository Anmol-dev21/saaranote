import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_colors.dart';
import '../viewmodels/note_viewmodel.dart';
import '../../domain/usecases/get_all_notes_usecase.dart';
import 'add_note_screen.dart';
import 'note_editor_screen.dart';
import 'note_detail_screen.dart';

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
        actions: [
          _buildFilterDropdown(context),
          AppSpacing.hGapSm,
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
            child: _buildSearchBar(context),
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
                        child: AppListCard(
                          title: note.title,
                          subtitle: '${note.content}\n${_formatDate(note.updatedAt)}',
                          leading: CircleAvatar(
                            backgroundColor: note.color != null
                                ? _parseColor(note.color!)
                                : Theme.of(context).colorScheme.primary,
                            child: const Icon(Icons.note, color: Colors.white, size: 20),
                          ),
                          trailing: _buildNoteActions(context, note.id!, viewModel),
                          onTap: () => _navigateToDetail(context, note.id!),
                        ),
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
            onPressed: () => _navigateToNoteEditor(context),
            tooltip: 'New Note (Rich Text & Drawing)',
            child: const Icon(Icons.draw),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _navigateToAddNote(context),
            tooltip: 'Quick Add (OCR/PDF)',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return AppSearchBar(
      controller: _searchController,
      hintText: 'Search notes...',
      onChanged: _onSearchChanged,
      onClear: () => _onSearchChanged(''),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    return PopupMenuButton<NoteSortBy>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort by',
      onSelected: (sort) {
        context.read<NoteViewModel>().setSortBy(sort);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: NoteSortBy.createdDateDesc,
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 18),
              SizedBox(width: 8),
              Text('Recent'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: NoteSortBy.createdDateAsc,
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 18),
              SizedBox(width: 8),
              Text('Oldest'),
            ],
          ),
        ),
      ],
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

        if (!context.mounted) return;

        if (value == 'delete') {
          final confirm = await _showDeleteConfirmation(context);
          if (!context.mounted) return;
          if (confirm == true) {
            final success = await viewModel.deleteNote(noteId);
            if (!context.mounted) return;
            if (success) {
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
      if (!context.mounted) return;
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
      if (!context.mounted) return;
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
