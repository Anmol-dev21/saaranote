import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';

/// Message bubble widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDeleteMessage;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.verticalSm,
      child: Row(
        mainAxisAlignment:
            message.role == MessageRole.user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.role == MessageRole.assistant) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              radius: 16,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            AppSpacing.hGapSm,
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.role == MessageRole.user
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: AppSpacing.paddingMd,
                  margin: AppSpacing.verticalSm,
                  decoration: BoxDecoration(
                    color: message.role == MessageRole.user
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.role == MessageRole.user
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (message.sources != null && message.sources!.isNotEmpty) ...[
                        AppSpacing.vGapMd,
                        _buildSources(context, message.sources!),
                      ],
                    ],
                  ),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (message.role == MessageRole.user) ...[
            AppSpacing.hGapSm,
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 16,
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSources(BuildContext context, List<CitedSource> sources) {
    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.source_outlined,
                size: 14,
                color: message.role == MessageRole.user
                    ? Colors.white70
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                'Sources (${sources.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: message.role == MessageRole.user
                          ? Colors.white70
                          : Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...sources.take(3).map(
                (source) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 12,
                        color: message.role == MessageRole.user
                            ? Colors.white70
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          source.fileName,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: message.role == MessageRole.user
                                        ? Colors.white70
                                        : Theme.of(context).primaryColor,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (sources.length > 3)
            Text(
              '+${sources.length - 3} more',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: message.role == MessageRole.user
                        ? Colors.white60
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
