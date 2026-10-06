// Small formatting helpers, written by hand so the app needs no extra package.

/// 1450 -> "LKR 1,450"
String formatMoney(num amount, {String currency = 'LKR'}) {
  final digits = amount.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$currency $sign$buffer';
}

/// 1475 -> "Rs. 1,475"
String formatRs(num amount) => formatMoney(amount, currency: 'Rs.');

/// 2 -> "2", 2.5 -> "2.5"
String formatQuantity(num quantity) {
  return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
}

/// "4:00 PM"
String formatClock(DateTime time) {
  return formatMinutesOfDay(time.hour * 60 + time.minute);
}

/// Minutes since midnight to a clock time: 480 -> "8:00 AM".
String formatMinutesOfDay(int minutes) {
  final hour24 = (minutes ~/ 60) % 24;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:$minute ${hour24 < 12 ? 'AM' : 'PM'}';
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// "Mon", "Tue" ...
String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

/// "12 Oct"
String formatDayMonth(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// "Today, 4:00 PM" / "Tomorrow, 9:00 AM" / "12 Oct, 9:00 AM"
String formatPickupSlot(DateTime pickup, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final String day;
  if (isSameDay(pickup, current)) {
    day = 'Today';
  } else if (isSameDay(pickup, current.add(const Duration(days: 1)))) {
    day = 'Tomorrow';
  } else if (isSameDay(pickup, current.subtract(const Duration(days: 1)))) {
    day = 'Yesterday';
  } else {
    day = formatDayMonth(pickup);
  }
  return '$day, ${formatClock(pickup)}';
}

/// "Just now", "12m ago", "2h ago", "3d ago"
String timeAgo(DateTime time, {DateTime? now}) {
  final minutes = (now ?? DateTime.now()).difference(time).inMinutes;
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  return '${hours ~/ 24}d ago';
}

enum PickupUrgency { overdue, immediate, soon, later }

class PickupCountdown {
  const PickupCountdown(this.label, this.urgency);

  /// "in 35m", "in 1h 5m", "Immediate" or "Overdue".
  final String label;
  final PickupUrgency urgency;

  bool get isUrgent =>
      urgency == PickupUrgency.overdue || urgency == PickupUrgency.immediate;
}

/// How long until the customer arrives.
PickupCountdown pickupCountdown(DateTime pickup, {DateTime? now}) {
  final minutes = pickup.difference(now ?? DateTime.now()).inMinutes;
  if (minutes < 0) {
    return const PickupCountdown('Overdue', PickupUrgency.overdue);
  }
  if (minutes <= 15) {
    return const PickupCountdown('Immediate', PickupUrgency.immediate);
  }
  return PickupCountdown(
    'in ${_span(minutes)}',
    minutes <= 45 ? PickupUrgency.soon : PickupUrgency.later,
  );
}

String _span(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;
  if (hours < 24) {
    return restMinutes == 0 ? '${hours}h' : '${hours}h ${restMinutes}m';
  }
  final days = hours ~/ 24;
  final restHours = hours % 24;
  return restHours == 0 ? '${days}d' : '${days}d ${restHours}h';
}
