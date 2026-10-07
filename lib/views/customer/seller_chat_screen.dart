import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../models/grocery_item_model.dart';
import '../../services/chat_service.dart';
import '../../services/grocery_service.dart';
import '../common/app_image_view.dart';

class SellerChatScreen extends StatefulWidget {
  final GroceryItem? product;
  final String? shopName;
  final String? sellerName;
  final String? sellerPhone;

  const SellerChatScreen({
    super.key,
    this.product,
    this.shopName,
    this.sellerName,
    this.sellerPhone,
  });

  @override
  State<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isRecordingVoice = false;

  final List<String> _quickInquiries = [
    '🌱 Is this freshly harvested today?',
    '⏱️ Can I pick up within 30 minutes?',
    '⚖️ Do you offer smaller custom portions?',
    '🏷️ Is there a bulk purchase discount?',
    '📦 Is this pesticide-free organic?',
    '📍 Where is the exact pickup counter?',
    '🛍️ Can you pack in paper bags?',
  ];

  @override
  void initState() {
    super.initState();
    ChatService().markAllAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text;
    if (text.trim().isEmpty) return;

    ChatService().sendCustomerMessage(
      text: text,
      product: widget.product,
      isQuickInquiry: customText != null,
    );

    if (customText == null) {
      _messageController.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _sendAttachedMessage(String text, String attachmentUrl) {
    ChatService().sendCustomerMessage(
      text: text,
      product: widget.product,
      attachmentUrl: attachmentUrl,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleVoiceNoteTap() {
    if (!_isRecordingVoice) {
      setState(() => _isRecordingVoice = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Recording voice note... Tap mic again to send'),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() => _isRecordingVoice = false);
      _sendMessage('🎤 Voice Note (0:08) - Item Inquiry');
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attach Media or Inquiry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _buildAttachmentOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take Produce Photo',
                subtitle: 'Snap a live photo of vegetables or fruit condition',
                color: AppColors.brandGreen,
                onTap: () {
                  Navigator.pop(ctx);
                  _sendAttachedMessage('Fresh produce condition photo', 'produce_snapshot.jpg');
                },
              ),
              const SizedBox(height: 8),
              _buildAttachmentOption(
                icon: Icons.photo_library_rounded,
                title: 'Pick from Gallery',
                subtitle: 'Attach saved grocery receipt or reference item',
                color: const Color(0xFF3B82F4),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendAttachedMessage('Reference item from photo album', 'gallery_reference.jpg');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog() {
    final phone = widget.sellerPhone ?? widget.product?.displaySellerPhone ?? '+94 71 987 6543';
    final shop = widget.shopName ?? widget.product?.displaySellerShopName ?? 'GreenLeaf Fresh Mart';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppColors.brandGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Call $shop',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Direct store line for instant inquiries and reservations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF868889),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.call_rounded, color: AppColors.brandGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling $shop at $phone...'),
                          backgroundColor: AppColors.brandGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      'Dial Number Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final shop = widget.shopName ?? widget.product?.displaySellerShopName ?? 'GreenLeaf Fresh Mart';
    final seller = widget.sellerName ?? widget.product?.displaySellerName ?? 'Sunil Weerasinghe';

    return ListenableBuilder(
      listenable: chatService,
      builder: (context, _) {
        final rawMessages = chatService.allMessages;
        final messages = _searchQuery.isEmpty
            ? rawMessages
            : rawMessages
                .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(shop, seller),
          body: Column(
            children: [
              // Pinned Product Context Banner
              if (widget.product != null) _buildProductContextBanner(widget.product!),

              // Search query badge if filtering
              if (_isSearching && _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Found ${messages.length} matching message(s)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Inquiries Chips
              _buildQuickInquiryBar(),

              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length + (chatService.isSellerTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && chatService.isSellerTyping) {
                      return _buildTypingIndicator(shop);
                    }
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // Bottom Input Bar
              _buildInputBar(shop),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String shop, String seller) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: 'Search in chat...',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          const SizedBox(width: 4),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          color: Color(0xFF1E293B),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2EB844), Color(0xFF1E8A31)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF2EB844),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '$seller • Online',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 22,
          ),
          tooltip: 'Search Messages',
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: const Icon(
            Icons.phone_rounded,
            color: AppColors.brandGreen,
            size: 22,
          ),
          tooltip: 'Call Seller',
          onPressed: _showCallDialog,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 21),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'clear') {
              _confirmClearChat();
            } else if (value == 'store') {
              _showCallDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'store',
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('Store Info', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Text('Clear Chat', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Conversation?',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'All current messages with this seller will be cleared.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ChatService().clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat history cleared', style: GoogleFonts.plusJakartaSans()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: Text('Clear', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContextBanner(GroceryItem product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: product.circleColor,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: AppImageView(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INQUIRING PRODUCT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandGreen,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.formattedPrice,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  GroceryService().addToCart(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.name} to Cart!'),
                      backgroundColor: AppColors.brandGreen,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  '+ Add to Cart',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInquiryBar() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: _quickInquiries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final text = _quickInquiries[index];
          return GestureDetector(
            onTap: () => _sendMessage(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isCustomer = msg.isFromCustomer;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCustomer) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.brandGreenSoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: AppColors.brandGreen,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Message copied to clipboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isCustomer
                      ? const LinearGradient(
                          colors: [Color(0xFF2EB844), Color(0xFF219638)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isCustomer ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCustomer ? 16 : 4),
                    bottomRight: Radius.circular(isCustomer ? 4 : 16),
                  ),
                  border: isCustomer
                      ? null
                      : Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isCustomer ? 0.08 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (msg.attachmentUrl != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCustomer
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_rounded,
                              size: 16,
                              color: isCustomer ? Colors.white : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Photo Attachment',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCustomer ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (msg.text.contains('🎤 Voice Note')) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCustomer
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppColors.brandGreenSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: isCustomer ? Colors.white : AppColors.brandGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [4, 10, 16, 8, 14, 18, 12, 6, 15, 9].map((h) {
                              return Container(
                                width: 3,
                                height: h.toDouble(),
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: BoxDecoration(
                                  color: isCustomer
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF64748B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '0:08',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCustomer
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        msg.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: isCustomer ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isCustomer
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (isCustomer) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.deliveryStatus == MessageDeliveryStatus.read ||
                                    msg.deliveryStatus == MessageDeliveryStatus.delivered
                                ? Icons.done_all_rounded
                                : (msg.deliveryStatus == MessageDeliveryStatus.sent
                                    ? Icons.done_rounded
                                    : Icons.access_time_rounded),
                            size: 13,
                            color: msg.deliveryStatus == MessageDeliveryStatus.read
                                ? const Color(0xFFB9F6CA)
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(String shop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandGreenSoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.eco_rounded,
                color: AppColors.brandGreen,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$shop is typing',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const _TypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(String shop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF64748B),
                  size: 19,
                ),
                onPressed: _showAttachmentSheet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message $shop...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _isRecordingVoice ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: _isRecordingVoice ? AppColors.error : const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: _handleVoiceNoteTap,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2EB844), Color(0xFF1E8A31)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_animController.value - delay) % 1.0;
            final opacity = (0.3 + 0.7 * (1.0 - (progress - 0.5).abs() * 2)).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
