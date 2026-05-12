import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/person.dart' as person_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      granted = await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return granted;
  }

  Future<void> schedulePersonReminders(List<person_model.Person> people) async {
    await _notifications.cancelAll();
    final now = DateTime.now();

    for (final person in people) {
      if ((person.birthday ?? '').isNotEmpty) {
        await _scheduleBirthdayReminder(person, now);
      }
      for (final anniversary in person.anniversaries) {
        await _scheduleAnniversaryReminder(person, anniversary, now);
      }
    }
  }

  Future<void> _scheduleBirthdayReminder(person_model.Person person, DateTime now) async {
    final birthday = _parseDate(person.birthday ?? '');
    if (birthday == null) return;

    final thisYear = DateTime(now.year, birthday.month, birthday.day);
    final nextBirthday = thisYear.isBefore(now)
        ? DateTime(now.year + 1, birthday.month, birthday.day)
        : thisYear;

    final scheduledDate = tz.TZDateTime.from(
      nextBirthday.subtract(const Duration(days: 1)).copyWith(hour: 9, minute: 0),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      person.id.hashCode,
      '生日提醒',
      '明天是 ${person.name} 的生日 🎂',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday_reminders',
          '生日提醒',
          channelDescription: '提醒即将到来的生日',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleAnniversaryReminder(
    person_model.Person person,
    person_model.Anniversary anniversary,
    DateTime now,
  ) async {
    final anniversaryDate = _parseDate(anniversary.date);
    if (anniversaryDate == null) return;

    final thisYear = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);
    final nextAnniversary = thisYear.isBefore(now)
        ? DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day)
        : thisYear;

    final scheduledDate = tz.TZDateTime.from(
      nextAnniversary.subtract(const Duration(days: 1)).copyWith(hour: 9, minute: 0),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      (person.id.hashCode + 1000000),
      '纪念日提醒',
      '明天是 ${person.name} 的${anniversary.title.isEmpty ? '纪念日' : anniversary.title} 💝',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'anniversary_reminders',
          '纪念日提醒',
          channelDescription: '提醒即将到来的纪念日',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
