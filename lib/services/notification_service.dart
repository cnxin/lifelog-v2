import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/person.dart' as person_model;
import '../models/lifelog_models.dart';

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

  /// 调度定期联系提醒
  /// [people] 人员列表
  /// [memories] 回忆列表，用于查找最近联系时间
  /// [contactIntervalDays] 联系间隔天数，默认30天
  Future<void> scheduleContactReminders(
    List<person_model.Person> people,
    List<MemoryEvent> memories,
    int contactIntervalDays,
  ) async {
    final now = DateTime.now();

    for (final person in people) {
      // 查找与该人员相关的最近一次回忆
      final personMemories = memories
          .where((m) => m.personIds.contains(person.id))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (personMemories.isEmpty) continue;

      final lastMemoryDate = _parseDate(personMemories.first.date);
      if (lastMemoryDate == null) continue;

      final daysSinceLastContact = now.difference(lastMemoryDate).inDays;

      // 如果超过设定天数，安排提醒
      if (daysSinceLastContact >= contactIntervalDays) {
        await _scheduleContactReminder(person, lastMemoryDate, daysSinceLastContact);
      }
    }
  }

  Future<void> _scheduleContactReminder(
    person_model.Person person,
    DateTime lastContactDate,
    int daysSinceLastContact,
  ) async {
    // 每天上午10点提醒
    final scheduledDate = tz.TZDateTime.from(
      DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0, second: 0, millisecond: 0),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      person.id.hashCode + 2000000,
      '定期联系提醒',
      '已经 $daysSinceLastContact 天没有联系 ${person.name} 了，要不要打个招呼？ 👋',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'contact_reminders',
          '定期联系提醒',
          channelDescription: '提醒定期联系重要的人',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 调度回忆回顾提醒
  /// [memories] 回忆列表
  Future<void> scheduleMemoryReviewReminders(List<MemoryEvent> memories) async {
    final now = DateTime.now();
    final todayMD = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 查找往年今天的回忆
    final pastMemories = memories.where((m) {
      final memoryDate = _parseDate(m.date);
      if (memoryDate == null) return false;
      if (memoryDate.year == now.year) return false; // 排除今年的

      final memoryMD = '${memoryDate.month.toString().padLeft(2, '0')}-${memoryDate.day.toString().padLeft(2, '0')}';
      return memoryMD == todayMD;
    }).toList();

    if (pastMemories.isEmpty) return;

    // 每天上午9点提醒
    final scheduledDate = tz.TZDateTime.from(
      DateTime.now().add(const Duration(days: 1)).copyWith(hour: 9, minute: 0, second: 0, millisecond: 0),
      tz.local,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final yearsAgo = now.year - _parseDate(pastMemories.first.date)!.year;
    final memoryTitle = pastMemories.first.title;

    await _notifications.zonedSchedule(
      9999999, // 固定ID，每天只有一个回忆回顾提醒
      '回忆回顾',
      '$yearsAgo 年前的今天：$memoryTitle 📸',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'memory_review_reminders',
          '回忆回顾提醒',
          channelDescription: '回顾往年今天的美好回忆',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
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
