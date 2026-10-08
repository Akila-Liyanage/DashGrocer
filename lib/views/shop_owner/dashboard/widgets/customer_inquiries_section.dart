import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../services/chat_service.dart';
import '../../chat/shop_owner_chat_screen.dart';
import '../../chat/shop_owner_conversations_screen.dart';

/// WhatsApp-style Customer Inbox card for the Seller Dashboard.
/// Shows all customer messages stacked vertically ("yatata yatata") with
/// customer names, avatars, message snippets, timestamps, and unread badges.
class CustomerInquiriesSection extends StatelessWidget {
  const CustomerInquiriesSection({super.key});

  static const Color waTeal = Color(0xFF008069);
  static const Color waGreen = Color(0xFF25D366);
  static const Color waBlueCheck = Color(0xFF53BDEB);
  static const Color waTextPrimary = Color(0xFF111B21);
  static const Color waTextSecondary = Color(0xFF667781);
  static const Color waDivider = Color(0xFFE9EDEF);

  void _openConversation(BuildContext context, ChatConversation conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopOwnerChatScreen(
          customerId: conv.customerId,
          customerName: conv.customerName,
          customerPhone: conv.customerPhone ?? '+94 77 123 4567',
          orderId: conv.latestOrderId,
        ),
      ),
    );
  }

  void _openAllConversations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ShopOwnerConversationsScreen(),
      ),
    );
  }

  Color _avatarBgColor(String name) {
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFF0D9488),
      const Color(0xFF16A34A),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return ListenableBuilder(
      listenable: chatService,
      builder: (context, _) {
        final conversations = chatService.getCustomerConversations();
        final unreadCount = chatService.sellerUnreadCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: waTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: waTeal,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Inquiries',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: waTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'WhatsApp-style chat list (${conversations.length} active)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: waTextSecondary,
                      ),
                    ),
                  ],
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: waGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount NEW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => _openAllConversations(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Inbox',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: waTeal,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: waTeal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vertically Stacked Chat Cards ("yatata yatata")
            if (conversations.isEmpty)
              _buildEmptyCard()
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 0.7,
                      indent: 72,
                      color: waDivider,
                    ),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      return _buildDashboardChatTile(context, conv);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Single WhatsApp Chat Tile inside the Dashboard Inbox card
  Widget _buildDashboardChatTile(BuildContext context, ChatConversation conv) {
    final hasUnread = conv.unreadCount > 0;
    final isFromSeller = conv.lastMessage.isFromSeller;

    return Material(
      color: hasUnread ? const Color(0xFFF0FDF4) : Colors.white,
      child: InkWell(
        onTap: () => _openConversation(context, conv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (48x48) with Initials & Online Green Indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: _avatarBgColor(conv.customerName),
                    child: Text(
                      conv.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: waGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),

              // Middle Column: Customer Name & Message Preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Customer Name (Bold) & Relative Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            conv.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: waTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conv.relativeTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread ? waGreen : waTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Bottom Row: Status Tick & Message Snippet & Unread Badge
                    Row(
                      children: [
                        if (isFromSeller) ...[
                          const Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: waBlueCheck,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conv.lastMessage.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                              color: hasUnread
                                  ? waTextPrimary
                                  : waTextSecondary,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: waGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Order / Product context pill
                    if (conv.latestOrderId != null || conv.latestProductName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (conv.latestOrderId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                conv.latestOrderId!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          if (conv.latestProductName != null)
                            Flexible(
                              child: Text(
                                '• ${conv.latestProductName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: waTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: waTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: waTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No customer chats yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: waTextPrimary,
                  ),
                ),
                Text(
                  'Customer inquiries from the catalog will appear here vertically like WhatsApp chats.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: waTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
