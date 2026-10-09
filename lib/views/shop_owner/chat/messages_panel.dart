import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import 'shop_owner_chat_screen.dart';

/// Opens the customer messages panel as a floating card above the chat
/// button, the same way the notifications panel opens under the header.
Future<void> showMessagesPanel(BuildContext context) {
  final navigator = Navigator.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _MessagesPanel(
      onOpenConversation: (conversation) {
        Navigator.of(dialogContext).pop();
        navigator.push(
          shopRoute<void>(
            (context) => ShopOwnerChatScreen(
              customerId: conversation.customerId,
              customerName: conversation.customerName,
              customerPhone: conversation.customerPhone ?? '+94 77 123 4567',
              orderId: conversation.latestOrderId,
            ),
          ),
        );
      },
    ),
  );
}

class _MessagesPanel extends StatelessWidget {
  const _MessagesPanel({required this.onOpenConversation});

  final ValueChanged<ChatConversation> onOpenConversation;

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Dialog(
      // Sits just above the chat button and the bottom navigation.
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 96),
      backgroundColor: ShopColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        // Listening to the chat service keeps the list live while the panel
        // is open.
        child: ListenableBuilder(
          listenable: chatService,
          builder: (context, child) {
            final conversations = chatService.getCustomerConversations();
            final unread = chatService.sellerUnreadCount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text('Messages', style: ShopText.title),
                      const SizedBox(width: 8),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ShopColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$unread New',
                            style: ShopText.label.copyWith(color: Colors.white),
                          ),
                        ),
                      const Spacer(),
                      if (unread > 0)
                        TextButton(
                          onPressed: chatService.markAllAsReadBySeller,
                          child: const Text('Mark all read'),
                        ),
                      IconButton(
                        tooltip: 'Close messages',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                if (conversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 32,
                          color: ShopColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        Text('No messages yet', style: ShopText.subtitle),
                        Text(
                          'Questions from your customers appear here.',
                          style: ShopText.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      itemCount: conversations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return _ConversationTile(
                          conversation: conversation,
                          onTap: () => onOpenConversation(conversation),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    // The order and product the customer is asking about, when known.
    final topic = [conversation.latestOrderId, conversation.latestProductName]
        .whereType<String>()
        .join(' • ');

    return Material(
      // Unread conversations are tinted; read ones are plain white.
      color: unread ? ShopColors.surfaceLow : ShopColors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ShopColors.greenContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.initials,
                  style: ShopText.bodyStrong.copyWith(
                    color: ShopColors.onGreenContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (unread)
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: ShopColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conversation.customerName,
                            style: ShopText.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            conversation.relativeTime,
                            style: ShopText.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isFromSeller
                                ? 'You: ${conversation.lastMessage.text}'
                                : conversation.lastMessage.text,
                            style: unread ? ShopText.bodyStrong : ShopText.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ShopColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style:
                                  ShopText.label.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (topic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic,
                        style: ShopText.label.copyWith(
                          color: ShopColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
