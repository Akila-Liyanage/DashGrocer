import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;

/// Number of reviews, average rating and the number of reviews per star.
class ReviewStats {
  final int count;
  final double average;
  final Map<int, int> starCounts;

  const ReviewStats({required this.count, required this.average, required this.starCounts});

  factory ReviewStats.from(List<Map<String, dynamic>> reviews) {
    final counts = {for (final star in [5, 4, 3, 2, 1]) star: 0};
    var sum = 0;
    for (final review in reviews) {
      final star = (review['rating'] as num).toInt();
      counts[star] = (counts[star] ?? 0) + 1;
      sum += star;
    }
    return ReviewStats(
      count: reviews.length,
      average: reviews.isEmpty ? 0 : sum / reviews.length,
      starCounts: counts,
    );
  }

  /// "1 review" / "74 reviews".
  String get countLabel => count == 1 ? '1 review' : '$count reviews';
}

/// Keeps the reviews customers write. Screens listen to it, so a new review
/// shows up at once, and (when Firestore is connected) on other phones too.
class ReviewService extends ChangeNotifier {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final Map<String, Map<String, dynamic>> _byId = {};
  int _sequence = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _listening = false;

  /// Starts following the Firestore "reviews" collection. Safe to call many
  /// times, and does nothing when Firestore is not available.
  void startListening() {
    if (_listening) return;
    try {
      _subscription = FirebaseFirestore.instance.collection('reviews').snapshots().listen(
        (snapshot) {
          var changed = false;
          for (final doc in snapshot.docs) {
            final review = _normalise(doc.id, doc.data());
            if (review != null && !_sameReview(_byId[doc.id], review)) {
              _byId[doc.id] = review;
              changed = true;
            }
          }
          if (changed) notifyListeners();
        },
        onError: (Object e) => debugPrint('Firestore reviews listen notice: $e'),
      );
      _listening = true;
    } catch (_) {
      // Firestore is not set up (for example in tests): reviews stay in memory.
    }
  }

  /// Reviews customers wrote for one product, newest first.
  List<Map<String, dynamic>> reviewsFor(String productName) {
    final list = _byId.values.where((r) => r['productName'] == productName).toList();
    list.sort((a, b) => timestampOf(b).compareTo(timestampOf(a)));
    return list;
  }

  /// Every review shown for a product, newest first: the reviews customers
  /// wrote plus a few starter reviews. The Reviews screen and the product page
  /// both use this, so the numbers they show always agree.
  List<Map<String, dynamic>> allReviewsFor(String productName) {
    final all = [...reviewsFor(productName), ...starterReviews()];
    all.sort((a, b) => timestampOf(b).compareTo(timestampOf(a)));
    return all;
  }

  /// How many reviews a product has, its average rating and the count per star.
  ReviewStats statsFor(String productName) => ReviewStats.from(allReviewsFor(productName));

  /// A few starter reviews every product starts with.
  static List<Map<String, dynamic>> starterReviews({DateTime? now}) {
    final base = now ?? DateTime.now();
    return [
      {
        'id': 'rev_init_1',
        'initial': 'O',
        'name': 'Olivia',
        'timestamp': base.subtract(const Duration(days: 2)).toIso8601String(),
        'rating': 5,
        'comment':
            'These apples are incredibly fresh and crisp! Picked up my order within 10 minutes at Green Mart.',
      },
      {
        'id': 'rev_init_2',
        'initial': 'D',
        'name': 'Da Silva',
        'timestamp': base.subtract(const Duration(days: 4)).toIso8601String(),
        'rating': 4,
        'comment':
            'These melons are incredibly fresh and juicy! Picked up my order within 10 minutes at Green Mart.',
      },
      {
        'id': 'rev_init_3',
        'initial': 'K',
        'name': 'Kasun Perera',
        'timestamp': base.subtract(const Duration(days: 7)).toIso8601String(),
        'rating': 5,
        'comment':
            'Super fast pickup service, completely zero waiting time. Vegetables were fresh and nicely packed.',
      },
    ];
  }

  /// Full, half or empty star for star number [index] (0-4), with the average
  /// rounded to the nearest half.
  static IconData starIcon(int index, double average) {
    final rounded = (average * 2).round() / 2;
    if (index + 1 <= rounded) return Icons.star_rounded;
    if (index + 0.5 == rounded) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  /// Adds a review, shows it straight away and saves it to Firestore.
  Map<String, dynamic> addReview({
    required String productName,
    required String name,
    required int rating,
    required String comment,
  }) {
    final now = DateTime.now();
    final review = <String, dynamic>{
      // The counter keeps ids different even when two reviews share a clock tick.
      'id': 'rev_${now.microsecondsSinceEpoch}_${_sequence++}',
      'initial': name.isNotEmpty ? name[0].toUpperCase() : 'U',
      'name': name,
      'rating': rating,
      'comment': comment,
      'productName': productName,
      'timestamp': now.toIso8601String(),
    };
    _byId[review['id'] as String] = review;
    notifyListeners();

    try {
      FirebaseFirestore.instance
          .collection('reviews')
          .doc(review['id'] as String)
          .set(review, SetOptions(merge: true))
          .catchError((Object e) => debugPrint('Firestore save review notice: $e'));
    } catch (_) {}
    return review;
  }

  /// When the review was written.
  static DateTime timestampOf(Map<String, dynamic> review) {
    final raw = review['timestamp'];
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    return DateTime.tryParse('$raw') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// "Just now", "5 min ago", "3 hours ago", "Yesterday", "2 days ago", "1 week ago"...
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }

  Map<String, dynamic>? _normalise(String id, Map<String, dynamic> data) {
    final rating = (data['rating'] as num?)?.toInt();
    final comment = data['comment'];
    final productName = data['productName'];
    if (rating == null || rating < 1 || rating > 5 || comment is! String || productName is! String) {
      return null;
    }
    final name = (data['name'] as String?)?.trim().isNotEmpty == true ? data['name'] as String : 'Customer';
    final rawTime = data['timestamp'];
    final timestamp = rawTime is Timestamp ? rawTime.toDate().toIso8601String() : '$rawTime';
    return <String, dynamic>{
      'id': id,
      'initial': (data['initial'] as String?)?.isNotEmpty == true ? data['initial'] : name[0].toUpperCase(),
      'name': name,
      'rating': rating,
      'comment': comment,
      'productName': productName,
      'timestamp': timestamp,
    };
  }

  bool _sameReview(Map<String, dynamic>? a, Map<String, dynamic> b) {
    if (a == null) return false;
    return a['rating'] == b['rating'] &&
        a['comment'] == b['comment'] &&
        a['name'] == b['name'] &&
        a['timestamp'] == b['timestamp'];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
