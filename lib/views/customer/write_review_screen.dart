import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class WriteReviewResult {
  final int rating;
  final String comment;

  const WriteReviewResult({required this.rating, required this.comment});
}

class WriteReviewScreen extends StatefulWidget {
  final String productName;

  const WriteReviewScreen({super.key, this.productName = ''});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return '5.0 - Excellent!';
      case 4:
        return '4.0 - Very Good';
      case 3:
        return '3.0 - Average';
      case 2:
        return '2.0 - Below Expectation';
      case 1:
        return '1.0 - Poor';
      default:
        return '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() {
    final comment = _commentController.text.trim();
    if (_rating == 0) {
      _showError('Please select a star rating first.');
      return;
    }
    if (comment.isEmpty) {
      _showError('Please write a brief review about your experience.');
      return;
    }
    Navigator.pop(context, WriteReviewResult(rating: _rating, comment: comment));
  }

  @override
  Widget build(BuildContext context) {
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Write Reviews',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            children: [
              Text(
                'What do you think ?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'please give your rating by clicking on\nthe stars below',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final filled = index < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 42,
                        color: filled ? const Color(0xFFFFB800) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    _ratingLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandGreenDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _commentController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 500, // keeps one review from filling the whole page
                  textInputAction: TextInputAction.newline,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(14),
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                    focusedBorder: fieldBorder.copyWith(
                      borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    'Submit review',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
