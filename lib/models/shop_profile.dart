import '../core/formatters.dart';
import 'firestore_dates.dart';

/// The shop's own details and settings, saved in `shops/{shopId}`.
/// Times are minutes since midnight, so 480 is 8:00 AM.
class ShopProfile {
  const ShopProfile({
    required this.id,
    this.name = 'My Grocery Shop',
    this.address = '',
    this.addressNote = '',
    this.phone = '',
    this.mobile = '',
    this.weekdayOpen = 480,
    this.weekdayClose = 1200,
    this.sundayOpen = 480,
    this.sundayClose = 840,
    this.sundayClosed = false,
    this.orderNotifications = true,
    this.slotMinutes = 30,
    this.maxOrdersPerSlot = 5,
    this.notificationsReadAt,
  });

  final String id;
  final String name;

  /// Where customers collect their orders.
  final String address;

  /// Extra pickup hint, for example "Front dispatch counter".
  final String addressNote;
  final String phone;
  final String mobile;

  /// Monday to Saturday opening and closing time.
  final int weekdayOpen;
  final int weekdayClose;
  final int sundayOpen;
  final int sundayClose;
  final bool sundayClosed;

  /// Whether new order alerts are shown.
  final bool orderNotifications;

  /// Length of one pickup slot offered to customers.
  final int slotMinutes;

  /// How many orders the shop accepts for the same pickup slot.
  final int maxOrdersPerSlot;

  /// Alerts older than this are shown as read.
  final DateTime? notificationsReadAt;

  String get weekdayHoursLabel =>
      '${formatMinutesOfDay(weekdayOpen)} – ${formatMinutesOfDay(weekdayClose)}';

  String get sundayHoursLabel => sundayClosed
      ? 'Closed'
      : '${formatMinutesOfDay(sundayOpen)} – ${formatMinutesOfDay(sundayClose)}';

  /// Start times (minutes since midnight) of the pickup slots on [day].
  List<int> pickupSlotsFor(DateTime day) {
    final isSunday = day.weekday == DateTime.sunday;
    if (isSunday && sundayClosed) return const <int>[];
    final open = isSunday ? sundayOpen : weekdayOpen;
    final close = isSunday ? sundayClose : weekdayClose;
    final step = slotMinutes <= 0 ? 30 : slotMinutes;
    return [
      for (var start = open; start + step <= close; start += step) start,
    ];
  }

  ShopProfile copyWith({
    String? name,
    String? address,
    String? addressNote,
    String? phone,
    String? mobile,
    int? weekdayOpen,
    int? weekdayClose,
    int? sundayOpen,
    int? sundayClose,
    bool? sundayClosed,
    bool? orderNotifications,
    int? slotMinutes,
    int? maxOrdersPerSlot,
    DateTime? notificationsReadAt,
  }) {
    return ShopProfile(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      addressNote: addressNote ?? this.addressNote,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      weekdayOpen: weekdayOpen ?? this.weekdayOpen,
      weekdayClose: weekdayClose ?? this.weekdayClose,
      sundayOpen: sundayOpen ?? this.sundayOpen,
      sundayClose: sundayClose ?? this.sundayClose,
      sundayClosed: sundayClosed ?? this.sundayClosed,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      maxOrdersPerSlot: maxOrdersPerSlot ?? this.maxOrdersPerSlot,
      notificationsReadAt: notificationsReadAt ?? this.notificationsReadAt,
    );
  }

  factory ShopProfile.fromMap(String id, Map<String, dynamic> map) {
    int number(String key, int fallback) {
      return (map[key] as num?)?.toInt() ?? fallback;
    }

    return ShopProfile(
      id: id,
      name: map['name'] as String? ?? 'My Grocery Shop',
      address: map['address'] as String? ?? '',
      addressNote: map['addressNote'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      mobile: map['mobile'] as String? ?? '',
      weekdayOpen: number('weekdayOpen', 480),
      weekdayClose: number('weekdayClose', 1200),
      sundayOpen: number('sundayOpen', 480),
      sundayClose: number('sundayClose', 840),
      sundayClosed: map['sundayClosed'] as bool? ?? false,
      orderNotifications: map['orderNotifications'] as bool? ?? true,
      slotMinutes: number('slotMinutes', 30),
      maxOrdersPerSlot: number('maxOrdersPerSlot', 5),
      notificationsReadAt: readDate(map['notificationsReadAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'addressNote': addressNote,
      'phone': phone,
      'mobile': mobile,
      'weekdayOpen': weekdayOpen,
      'weekdayClose': weekdayClose,
      'sundayOpen': sundayOpen,
      'sundayClose': sundayClose,
      'sundayClosed': sundayClosed,
      'orderNotifications': orderNotifications,
      'slotMinutes': slotMinutes,
      'maxOrdersPerSlot': maxOrdersPerSlot,
      'notificationsReadAt': writeDate(notificationsReadAt),
    };
  }
}
