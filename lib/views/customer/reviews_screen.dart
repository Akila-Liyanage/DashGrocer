import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import 'write_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final String productName;

  const ReviewsScreen({
    super.key,
    this.productName = 'Fresh Produce & Groceries',
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  int _selectedFilterIndex = 0;
  String _sortOrder = 'Most recent';

  final ReviewService _reviewService = ReviewService();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _reviewService.addListener(_onReviewsChanged);
    _reviewService.startListening();
    // Labels like "5 min ago" keep moving while the screen stays open.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => _onReviewsChanged());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _reviewService.removeListener(_onReviewsChanged);
    super.dispose();
  }

  void _onReviewsChanged() {
    if (mounted) setState(() {});
  }

  String _timeLabel(Map<String, dynamic> review) =>
      ReviewService.timeAgo(ReviewService.timestampOf(review));

  Future<void> _showWriteReviewModal() async {
    final result = await Navigator.push<WriteReviewResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(productName: widget.productName),
      ),
    );
    if (result == null || !mounted) return;

    final fullName = AuthService().currentUser?.fullName ?? '';
    _addReview(
      name: fullName.isNotEmpty ? fullName : 'Kasun Perera',
      rating: result.rating,
      comment: result.comment,
    );
  }

  void _addReview({
    required String name,
    required int rating,
    required String comment,
  }) {
    _reviewService.addReview(
      productName: widget.productName,
      name: name,
      rating: rating,
      comment: comment,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎉 Thank you, $name! Your review has been published.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final userInitial = (currentUser?.fullName.isNotEmpty == true)
        ? currentUser!.fullName[0].toUpperCase()
        : 'N';

    // Everything shown below is worked out from the reviews, so it changes as
    // soon as a review is added (here, or on another phone).
    final reviews = _reviewService.allReviewsFor(widget.productName);
    final stats = _reviewService.statsFor(widget.productName);
    final counts = stats.starCounts;
    final total = stats.count;
    final average = stats.average;
    // Chip 0 is "All", chips 1-5 are the 5, 4, 3, 2 and 1 star reviews.
    final filters = [
      'All ($total)',
      for (final star in [5, 4, 3, 2, 1]) '$star ★ (${counts[star] ?? 0})',
    ];

    var filteredReviews = reviews;
    if (_selectedFilterIndex > 0) {
      final star = 6 - _selectedFilterIndex;
      filteredReviews = reviews.where((r) => r['rating'] == star).toList();
    }

    if (_sortOrder == 'Highest rating') {
      filteredReviews = List.from(filteredReviews)
        ..sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Reviews',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Ratings Summary Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left: Big Score & Stars
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                total == 0 ? '–' : average.toStringAsFixed(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    ReviewService.starIcon(index, average),
                                    size: 16,
                                    color: const Color(0xFFFFB800),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                total == 0
                                    ? 'No reviews yet'
                                    : (total == 1 ? '1 Review' : '$total Reviews'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF868889),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 24),

                          // Right: Horizontal Star Distribution Bars
                          Expanded(
                            child: Column(
                              children: [
                                for (final star in [5, 4, 3, 2, 1])
                                  _buildRatingBar(
                                    star: '$star',
                                    count: counts[star] ?? 0,
                                    percentage: total > 0 ? (counts[star] ?? 0) / total : 0,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Write a Review Prompt Card
                    InkWell(
                      onTap: _showWriteReviewModal,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.brandGreenSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  userInitial,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Write a review',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Share your experience',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF868889),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Filter Chips: [All (125)] [5 ★ (97)] [4 ★ (20)] [3 ★] [2 ★] [1 ★]
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                      children: List.generate(filters.length, (index) {
                        final isSelected = _selectedFilterIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilterIndex = index),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brandGreenSoft : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? AppColors.brandGreen : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                filters[index],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.brandGreenDark : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent reviews header & sort
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent reviews',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            setState(() => _sortOrder = val);
                          },
                          child: Row(
                            children: [
                              Text(
                                _sortOrder,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.brandGreenDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppColors.brandGreenDark, size: 18),
                            ],
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Most recent', child: Text('Most recent')),
                            const PopupMenuItem(value: 'Highest rating', child: Text('Highest rating')),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Reviews List
                    if (filteredReviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            _selectedFilterIndex == 0
                                ? 'No reviews yet. Be the first to write one!'
                                : 'No ${6 - _selectedFilterIndex}-star reviews to show yet.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ...filteredReviews.map((rev) => _buildReviewTile(rev)),
                  ],
                ),
              ),
            ),

            // Bottom "Back To Home" Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Back To Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar({required String star, required int count, required double percentage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Text(
              star,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF868889),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandGreenSoft,
                radius: 16,
                child: Text(
                  review['initial'] ?? 'U',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.brandGreenDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] ?? 'Customer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _timeLabel(review),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF868889),
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 15,
                    color: const Color(0xFFFFB800),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Comment
          Text(
            review['comment'] ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Action Icons: Reply & Share
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
              SizedBox(width: 16),
              Icon(Icons.share_outlined, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }
}
