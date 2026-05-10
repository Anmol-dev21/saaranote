import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_components.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/chat_input_field.dart';
import '../widgets/chat/quick_action_bar.dart';
import '../widgets/chat/scope_chip.dart';

/// AI Chat screen for interacting with the offline assistant
class ChatScreen extends StatefulWidget {
  final int? sessionId;

  const ChatScreen({
    super.key,
    this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    final viewModel = context.read<ChatViewModel>();
    await viewModel.initializeSession(sessionId: widget.sessionId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_inputController.text.trim().isEmpty) return;

    final viewModel = context.read<ChatViewModel>();
    final message = _inputController.text;
    _inputController.clear();

    await viewModel.sendQuestion(message);
    _scrollToBottom();
  }

  Future<void> _handleQuickAction(QuickAction action) async {
    final viewModel = context.read<ChatViewModel>();
    await viewModel.executeQuickAction(action);
    _scrollToBottom();
  }

  void _showScopeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ScopeSelector(
        onScopeSelected: (folderId, folderName, noteIds) {
          final viewModel = context.read<ChatViewModel>();
          if (folderId != null) {
            viewModel.setScopeToFolder(folderId, folderName!);
          } else if (noteIds != null) {
            viewModel.setScopeToNotes(noteIds);
          } else {
            viewModel.clearScope();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show chat history
            },
            tooltip: 'Chat History',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showScopeSelector,
            tooltip: 'Set Scope',
          ),
        ],
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && !viewModel.hasMessages) {
            return const AppLoadingIndicator(message: 'Initializing chat...');
          }

          return Column(
            children: [
              // Scope indicator
              if (viewModel.hasScope)
                Container(
                  width: double.infinity,
                  padding: AppSpacing.pagePadding,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: ScopeChip(
                    label: viewModel.scopedFolderName ?? 'Selected Notes',
                    onClear: viewModel.clearScope,
                  ),
                ),

              // Messages list
              Expanded(
                child: viewModel.hasMessages
                    ? ListView.builder(
                        controller: _scrollController,
                        padding: AppSpacing.pagePadding,
                        itemCount: viewModel.messages.length,
                        itemBuilder: (context, index) {
                          final message = viewModel.messages[index];
                          return MessageBubble(
                            message: message,
                            onDeleteMessage: () async {
                              if (message.id != null) {
                                await viewModel.deleteMessage(message.id!);
                              }
                            },
                          );
                        },
                      )
                    : AppEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Start a Conversation',
                        message: 'Ask me anything about your notes!',
                      ),
              ),

              // Error banner
              if (viewModel.hasError)
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingMd,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          viewModel.errorMessage ?? 'An error occurred',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: viewModel.clearError,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),

              // Quick action bar
              QuickActionBar(
                onAction: _handleQuickAction,
                isLoading: viewModel.isSending,
              ),

              // Input field
              ChatInputField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                onSend: _sendMessage,
                isLoading: viewModel.isSending,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom sheet for selecting scope (folder/notes)
class _ScopeSelector extends StatelessWidget {
  final Function(int? folderId, String? folderName, List<int>? noteIds) onScopeSelected;

  const _ScopeSelector({
    required this.onScopeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask from...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.vGapMd,
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('All Notes'),
            subtitle: const Text('Search across all your notes'),
            onTap: () => onScopeSelected(null, null, null),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Select Folder'),
            subtitle: const Text('Ask from notes in a specific folder'),
            onTap: () {
              // TODO: Show folder selector
              // For now, just close
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Select Notes'),
            subtitle: const Text('Ask from specific notes'),
            onTap: () {
              // TODO: Show note selector
              // For now, just close
              Navigator.pop(context);
            },
          ),
          AppSpacing.vGapLg,
        ],
      ),
    );
  }
}
