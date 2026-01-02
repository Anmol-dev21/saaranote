import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/note_viewmodel.dart';
import '../../domain/usecases/get_all_notes_usecase.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';

/// Home screen displaying the list of notes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load notes when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteViewModel>().fetchNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saaranote'),
        actions: [
          _buildFilterMenu(context),
          _buildSortMenu(context),
        ],
      ),
      body: Consumer<NoteViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage ?? 'An error occurred',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => viewModel.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasNotes) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first note',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            child: ListView.builder(
              itemCount: viewModel.noteCount,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final note = viewModel.notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(note.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: note.color != null
                          ? _parseColor(note.color!)
                          : Theme.of(context).primaryColor,
                      child: const Icon(Icons.note, color: Colors.white),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterMenu(BuildContext context) {
    return PopupMenuButton<NoteFilter>(
      icon: const Icon(Icons.filter_list),
      onSelected: (filter) {
        context.read<NoteViewModel>().setFilter(filter);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: NoteFilter.active,
          child: Text('Active'),
        ),
        const PopupMenuItem(
          value: NoteFilter.all,
          child: Text('All'),
        ),
        const PopupMenuItem(
          value: NoteFilter.archived,
          child: Text('Archived'),
        ),
      ],
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    return PopupMenuButton<NoteSortBy>(
      icon: const Icon(Icons.sort),
      onSelected: (sort) {
        context.read<NoteViewModel>().setSortBy(sort);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: NoteSortBy.createdDateDesc,
          child: Text('Newest First'),
        ),
        const PopupMenuItem(
          value: NoteSortBy.createdDateAsc,
          child: Text('Oldest First'),
        ),
        const PopupMenuItem(
          value: NoteSortBy.updatedDateDesc,
          child: Text('Recently Updated'),
        ),
        const PopupMenuItem(
          value: NoteSortBy.titleAsc,
          child: Text('Title A-Z'),
        ),
      ],
    );
  }

  Widget _buildNoteActions(BuildContext context, int noteId, NoteViewModel viewModel) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'delete':
            final confirm = await _showDeleteConfirmation(context);
            if (confirm == true && context.mounted) {
              final success = await viewModel.deleteNote(noteId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note deleted')),
                );
              }
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
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
