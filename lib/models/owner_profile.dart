/// The logged-in shop owner's personal details, saved in `users/{userId}`.
///
/// The Firestore field names (`fullName`, `email`, `phoneNumber`) are the
/// same ones the login part uses for its user, so both parts can share the
/// same document.
class OwnerProfile {
  const OwnerProfile({
    required this.id,
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.photoUrl,
  });

  /// The user id. One owner has one shop, and the shop uses the same id.
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;

  /// Either a web link, or a small photo stored as a `data:` URI.
  final String? photoUrl;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// "Kamal Perera" -> "KP". Empty when no name is set yet.
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  /// Pass `removePhoto: true` to clear the photo.
  OwnerProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    bool removePhoto = false,
  }) {
    return OwnerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: removePhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }

  factory OwnerProfile.fromMap(String id, Map<String, dynamic> map) {
    return OwnerProfile(
      id: id,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }
}
