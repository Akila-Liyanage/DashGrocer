import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import 'shop_owner_chat_screen.dart';

/// WhatsApp-style Customer Inbox screen for the Shop Owner
/// Lists all customer conversations vertically ("yatata yatata") with
/// real-time status, customer names, last messages, unread badges, and order links.
class ShopOwnerConversationsScreen extends StatefulWidget {
  const ShopOwnerConversationsScreen({super.key});

  @override
  State<ShopOwnerConversationsScreen> createState() =>
      _ShopOwnerConversationsScreenState();
}

class _ShopOwnerConversationsScreenState
    extends State<ShopOwnerConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Unread', 'Orders'

  // WhatsApp Color Palette
  static const Color waTeal = Color(0xFF008069);
  static const Color waTealDark = Color(0xFF075E54);
  static const Color waGreen = Color(0xFF25D366);
  static const Color waBlueCheck = Color(0xFF53BDEB);
  static const Color waTextPrimary = Color(0xFF111B21);
  static const Color waTextSecondary = Color(0xFF667781);
  static const Color waDivider = Color(0xFFE9EDEF);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChatWithCustomer(ChatConversation conv) {
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

  Color _avatarBgColor(String name) {
    final colors = [
      const Color(0xFF0284C7), // Sky blue
      const Color(0xFF0D9488), // Teal
      const Color(0xFF16A34A), // Green
      const Color(0xFFEA580C), // Orange
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFDB2777), // Pink
    ];
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(chatService),
      body: Column(
        children: [
          // WhatsApp Search Bar
          _buildSearchBar(),

          // Filter Chips (All, Unread, Orders)
          _buildFilterPills(chatService),

          const Divider(height: 1, thickness: 0.8, color: waDivider),

          // Vertically Stacked Customer Chats List ("yatata yatata")
          Expanded(
            child: ListenableBuilder(
              listenable: chatService,
              builder: (context, _) {
                final allConversations = chatService.getCustomerConversations();

                final filtered = allConversations.where((conv) {
                  if (_activeFilter == 'Unread' && conv.unreadCount == 0) {
                    return false;
                  }
                  if (_activeFilter == 'Orders' && conv.latestOrderId == null) {
                    return false;
                  }
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return conv.customerName.toLowerCase().contains(q) ||
                      conv.lastMessage.text.toLowerCase().contains(q) ||
                      (conv.latestOrderId?.toLowerCase().contains(q) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(allConversations.isEmpty);
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 76,
                    color: waDivider,
                  ),
                  itemBuilder: (context, index) {
                    final conv = filtered[index];
                    return _buildWhatsAppChatTile(conv);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: waTeal,
        tooltip: 'All Messages Read',
        onPressed: () {
          chatService.markAllAsReadBySeller();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'All customer messages marked as read ✓✓',
                style: GoogleFonts.plusJakartaSans(),
              ),
              backgroundColor: waTealDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(
          Icons.mark_chat_read_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatService chatService) {
    return AppBar(
      backgroundColor: waTeal,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          color: Colors.white,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Messages',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              ListenableBuilder(
                listenable: chatService,
                builder: (context, _) {
                  final unread = chatService.sellerUnreadCount;
                  final total = chatService.getCustomerConversations().length;
                  return Text(
                    unread > 0
                        ? '$total customer${total == 1 ? '' : 's'} • $unread unread'
                        : '$total customer conversation${total == 1 ? '' : 's'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: unread > 0
                          ? const Color(0xFFA7F3D0) // Light green alert
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search Chats',
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () {
            // Scroll to or focus search bar
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'read_all') {
              chatService.markAllAsReadBySeller();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'read_all',
              child: Row(
                children: [
                  const Icon(Icons.done_all_rounded, size: 18, color: waTeal),
                  const SizedBox(width: 8),
                  Text(
                    'Mark all as read',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// WhatsApp-style Search Bar placed at the top of the chat list
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: waTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search customer name or message...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: waTextSecondary,
              fontSize: 13.5,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: waTextSecondary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: waTextSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
      ),
    );
  }

  Widget _buildFilterPills(ChatService chatService) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildPill('All', Icons.forum_rounded),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: chatService,
            builder: (context, _) {
              final unread = chatService.sellerUnreadCount;
              return _buildPill(
                'Unread',
                Icons.mark_chat_unread_rounded,
                badgeCount: unread,
              );
            },
          ),
          const SizedBox(width: 8),
          _buildPill('Orders', Icons.receipt_long_rounded),
        ],
      ),
    );
  }

  Widget _buildPill(String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _activeFilter == title;
    return InkWell(
      onTap: () => setState(() => _activeFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8F6EB)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? waTeal : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? waTeal : waTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? waTeal : waTextSecondary,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: const BoxDecoration(
                  color: waGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Authentic WhatsApp Chat Tile - Stacked Vertically ("yatata yatata")
  Widget _buildWhatsAppChatTile(ChatConversation conv) {
    final hasUnread = conv.unreadCount > 0;
    final isFromSeller = conv.lastMessage.isFromSeller;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openChatWithCustomer(conv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // WhatsApp Circular Avatar (50x50) with Initials & Online Dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _avatarBgColor(conv.customerName),
                    child: Text(
                      conv.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
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
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: waGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: waTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conv.relativeTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread ? waGreen : waTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Bottom Row: Status Icons (Ticks) & Message Preview & Unread Badge
                    Row(
                      children: [
                        if (isFromSeller) ...[
                          const Icon(
                            Icons.done_all_rounded,
                            size: 15,
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
                              fontSize: 13,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                              color: hasUnread
                                  ? waTextPrimary
                                  : waTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: waGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Context Pill (Order ID or Product Tag)
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 10,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    conv.latestOrderId!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (conv.latestProductName != null)
                            Flexible(
                              child: Text(
                                '• ${conv.latestProductName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: waTeal,
                                  fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState(bool isNoConversationsEver) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F6EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: waTeal,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isNoConversationsEver
                  ? 'No customer chats yet'
                  : 'No conversations match your search',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: waTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNoConversationsEver
                  ? 'Incoming customer messages from the store catalog will appear here vertically like WhatsApp chats.'
                  : 'Try typing another customer name or clear active filter chips.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: waTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
