import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_components.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../domain/entities/chat_message.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

/// AI chat screen for querying notes
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();

  final List<String> _suggestedPrompts = const [
    'Summarize my notes on calculus',
    'What did I learn about photosynthesis?',
    'Find notes from last week',
    'Turn this topic into flashcards',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New conversation',
            onPressed: () => _startNewConversation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContextStrip(context),
          Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, chat, child) {
                  if (chat.isLoading && chat.messages.isEmpty) {
                    return const AppLoadingIndicator(message: 'Loading chat...');
                  }

                  return ListView(
                    padding: AppSpacing.pagePadding.add(AppSpacing.verticalMd),
                    children: [
                      _buildConversationPreview(context, chat),
                    ],
                  );
                },
              ),
          ),
          _buildComposer(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildContextStrip(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
      child: Container(
        padding: AppSpacing.paddingSm,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Context',
              style: AppTypography.bodySmall(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppChip(
                    label: 'All notes',
                    selected: true,
                    onTap: () {},
                  ),
                  AppChip(
                    label: 'Selected folder',
                    selected: false,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationPreview(BuildContext context, ChatViewModel chat) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsViewModel>();
    final hasMessages = chat.messages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInfoBanner(
          message: 'Ask me anything about your notes. Answers stay offline.',
          icon: Icons.auto_awesome,
        ),
        if (!settings.offlineChatEnabled) ...[
          AppSpacing.vGapSm,
          AppInfoBanner(
            message: 'Offline chat is disabled in Settings.',
            icon: Icons.lock_outline,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            textColor: theme.colorScheme.onSurfaceVariant,
          ),
        ],
        if (chat.hasError) ...[
          AppSpacing.vGapSm,
          AppInfoBanner(
            message: chat.errorMessage ?? 'Something went wrong.',
            icon: Icons.error_outline,
            backgroundColor: theme.colorScheme.errorContainer,
            textColor: theme.colorScheme.onErrorContainer,
          ),
          AppSpacing.vGapXs,
          TextButton.icon(
            onPressed: () => chat.refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry loading chats'),
          ),
        ],
        AppSpacing.vGapLg,
        if (!hasMessages)
          AppEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Start your first chat',
            message: 'Ask a question to search your notes and summaries.',
          ),
        if (hasMessages) _buildMessageList(context, chat.messages),
        if (chat.isSending) ...[
          AppSpacing.vGapXs,
          _buildTypingIndicator(context),
        ],
        AppSpacing.vGapLg,
        _buildPromptSection(context),
      ],
    );
  }

  Widget _buildMessageList(BuildContext context, List<ChatMessage> messages) {
    return Column(
      children: messages
          .map((message) => _buildMessageBubble(context, message))
          .toList(),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerLow;
    final textColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final alignment = isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final assistantMeta = _extractAssistantContent(message);
    final content = assistantMeta.content;

    return Padding(
      padding: AppSpacing.verticalXs,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isUser && assistantMeta.isNoResults) ...[
            AppInfoBanner(
              message: 'No close matches found. Try a keyword from the note.',
              icon: Icons.search_off,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.vGapXs,
          ],
          if (!isUser && assistantMeta.isLowConfidence) ...[
            AppInfoBanner(
              message: 'Low confidence answer. Consider rephrasing your question.',
              icon: Icons.warning_amber_outlined,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              textColor: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.vGapXs,
          ],
          _buildMessageHeader(context, message),
          AppSpacing.vGapXs,
          Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
            ),
          ),
          if (message.sources != null && message.sources!.isNotEmpty) ...[
            AppSpacing.vGapXs,
            _buildCitationList(context, message.sources!),
          ],
          AppSpacing.vGapXs,
          _buildMessageStatus(context, message),
        ],
      ),
    );
  }

  Widget _buildMessageHeader(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final avatarColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onSurfaceVariant;
    final avatar = Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          isUser ? 'You' : 'AI',
          style: theme.textTheme.labelSmall?.copyWith(
            color: avatarColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final nameText = Text(
      isUser ? 'You' : 'Saara AI',
      style: theme.textTheme.bodySmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
    final timeText = Text(
      _formatTime(message.timestamp),
      style: theme.textTheme.bodySmall?.copyWith(
        color: textColor,
      ),
    );

    final children = isUser
        ? [timeText, AppSpacing.hGapXs, nameText, AppSpacing.hGapSm, avatar]
        : [avatar, AppSpacing.hGapSm, nameText, AppSpacing.hGapXs, timeText];

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildMessageStatus(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final statusColor = theme.colorScheme.onSurfaceVariant;
    final isUser = message.role == MessageRole.user;
    final statusLabel = _statusLabel(message);

    final statusIcon = message.status == MessageStatus.error
        ? Icons.error_outline
        : isUser
            ? Icons.check_circle_outline
            : Icons.auto_awesome;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(
          statusIcon,
          size: 14,
          color: statusColor,
        ),
        AppSpacing.hGapXs,
        Text(
          statusLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Row(
      children: [
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              _buildTypingDot(dotColor),
              AppSpacing.hGapXs,
              _buildTypingDot(dotColor),
              AppSpacing.hGapXs,
              _buildTypingDot(dotColor),
              AppSpacing.hGapSm,
              Text(
                'Generating answer...',
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

  Widget _buildTypingDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  _AssistantContent _extractAssistantContent(ChatMessage message) {
    if (message.role != MessageRole.assistant) {
      return _AssistantContent(
        content: message.content,
        isLowConfidence: false,
        isNoResults: false,
      );
    }

    var content = message.content;
    const marker = '\n\nSOURCES';
    final index = content.indexOf(marker);
    if (index != -1) {
      content = content.substring(0, index).trim();
    }

    final lowConfidencePrefix = RegExp(r'^LOW CONFIDENCE:\s*', caseSensitive: false);
    final isLowConfidence = lowConfidencePrefix.hasMatch(content.trim());
    content = content.replaceFirst(lowConfidencePrefix, '').trim();

    final isNoResults = content
        .toLowerCase()
        .contains('no relevant information found in your notes');

    return _AssistantContent(
      content: content,
      isLowConfidence: isLowConfidence,
      isNoResults: isNoResults,
    );
  }

  String _statusLabel(ChatMessage message) {
    switch (message.status) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.error:
        return 'Error';
      case MessageStatus.sent:
        return message.role == MessageRole.user ? 'Sent' : 'Answered';
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildCitationList(BuildContext context, List<CitedSource> citations) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sources',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.vGapXs,
        Column(
          children: citations
              .map((citation) => _buildCitationCard(context, citation))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCitationCard(BuildContext context, CitedSource citation) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.verticalXs,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    citation.fileName,
                    style: theme.textTheme.titleSmall,
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    citation.excerpt,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                citation.relevanceScore.toStringAsFixed(2),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try a prompt',
          style: theme.textTheme.titleMedium,
        ),
        AppSpacing.vGapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _suggestedPrompts
              .map((prompt) => _buildPromptChip(context, prompt))
              .toList(),
        ),
        AppSpacing.vGapLg,
        AppCard(
          padding: AppSpacing.paddingMd,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep your questions focused',
                      style: theme.textTheme.titleMedium,
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      'Ask about one topic at a time for clearer answers and citations.',
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
      ],
    );
  }

  Widget _buildPromptChip(BuildContext context, String label) {
    return AppChip(
      label: label,
      selected: false,
      onTap: () => _usePrompt(context, label),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsViewModel>();
    final isEnabled = settings.offlineChatEnabled;

    return SafeArea(
      top: false,
      child: Container(
        padding: AppSpacing.pagePadding.add(AppSpacing.verticalSm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                enabled: isEnabled,
                decoration: InputDecoration(
                  hintText: 'Ask about your notes...',
                  hintStyle: AppTypography.bodySmall(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapSm,
            IconButton(
              onPressed: isEnabled ? () => _sendMessage(context) : null,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 2) return;
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

  void _usePrompt(BuildContext context, String prompt) {
    _inputController.text = prompt;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    final settings = context.read<SettingsViewModel>();
    if (!settings.offlineChatEnabled) {
      _showSnackBar(context, 'Enable offline chat in Settings to send messages');
      return;
    }
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      _showSnackBar(context, 'Type a question to send');
      return;
    }

    _inputController.clear();
    await context.read<ChatViewModel>().sendMessage(text);
  }

  void _startNewConversation(BuildContext context) {
    _inputController.clear();
    context.read<ChatViewModel>().createNewSession();
  }

  void _showComingSoon(BuildContext context) {
    _showSnackBar(context, 'Coming soon');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AssistantContent {
  final String content;
  final bool isLowConfidence;
  final bool isNoResults;

  const _AssistantContent({
    required this.content,
    required this.isLowConfidence,
    required this.isNoResults,
  });
}

