import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a date that may be a Firestore Timestamp, a DateTime or text.
DateTime? readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Converts a date for saving in Firestore.
Timestamp? writeDate(DateTime? value) {
  return value == null ? null : Timestamp.fromDate(value);
}
