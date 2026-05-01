import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PendingDebtNotificationData {
  const PendingDebtNotificationData({
    required this.debtId,
    required this.customerName,
    required this.pendingAmount,
    required this.isPaid,
  });

  final String debtId;
  final String customerName;
  final double pendingAmount;
  final bool isPaid;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'debts_channel';
  static const String _channelName = 'Deudas';
  static const String _channelDescription =
      'Alertas de deudas pendientes, intereses y recordatorios de cobro';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final localTimezone = await _safeGetLocalTimezone();
    _setLocalTimezone(localTimezone);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await init();
    final id = _uniqueId();
    await _plugin.show(id, title, body, _notificationDetails());
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    final scheduled = _coerceToFuture(
      tz.TZDateTime.from(scheduledDate, tz.local),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelPendingDebtNotification(String debtId) async {
    await cancelNotification(_pendingDebtNotificationId(debtId));
  }

  Future<void> cancelDebtReminder(String debtId) async {
    await cancelNotification(_reminderNotificationId(debtId));
  }

  Future<void> ensureDailyPendingDebtNotification({
    required String debtId,
    required String customerName,
    required double pendingAmount,
    int hour = 9,
    int minute = 0,
  }) async {
    await init();

    final id = _pendingDebtNotificationId(debtId);
    final title = 'Deuda pendiente';
    final body =
        '$customerName tiene ${_formatMoney(pendingAmount)} pendientes';

    final needsUpdate = await _needsUpdate(id: id, title: title, body: body);
    if (!needsUpdate) return;

    final scheduled = _nextInstanceOfTime(hour: hour, minute: minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> syncPendingDebtNotifications({
    required List<PendingDebtNotificationData> debts,
    int hour = 9,
    int minute = 0,
  }) async {
    await init();

    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((p) => p.id).toSet();

    final desiredIds = <int>{};
    for (final debt in debts) {
      final id = _pendingDebtNotificationId(debt.debtId);
      if (debt.isPaid || debt.pendingAmount <= 0) {
        if (pendingIds.contains(id)) {
          await cancelNotification(id);
        }
        continue;
      }

      desiredIds.add(id);
      final title = 'Deuda pendiente';
      final body =
          '${debt.customerName} tiene ${_formatMoney(debt.pendingAmount)} pendientes';
      final existing = pending.firstWhere(
        (p) => p.id == id,
        orElse: () => const PendingNotificationRequest(0, '', '', ''),
      );
      if (existing.id == id &&
          existing.title == title &&
          existing.body == body) {
        continue;
      }
      await ensureDailyPendingDebtNotification(
        debtId: debt.debtId,
        customerName: debt.customerName,
        pendingAmount: debt.pendingAmount,
        hour: hour,
        minute: minute,
      );
    }

    final toCancel = pendingIds.where(
      (id) => id >= _pendingDebtIdBase && id < _pendingDebtIdBase + _idRange,
    );
    for (final id in toCancel) {
      if (!desiredIds.contains(id)) {
        await cancelNotification(id);
      }
    }
  }

  Future<void> scheduleDebtReminder({
    required String debtId,
    required String customerName,
    required DateTime scheduledDate,
  }) async {
    final id = _reminderNotificationId(debtId);
    final title = 'Recordatorio de cobro';
    final body = 'Hoy debes cobrar a $customerName';
    await cancelNotification(id);
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> ensureMonthlyDebtReminder({
    required String debtId,
    required String customerName,
    int dayOfMonth = 1,
    int hour = 9,
    int minute = 0,
  }) async {
    await init();

    final id = _reminderNotificationId(debtId);
    final title = 'Recordatorio de cobro';
    final body = 'Hoy debes cobrar a $customerName';
    final needsUpdate = await _needsUpdate(id: id, title: title, body: body);
    if (!needsUpdate) return;

    final scheduled = _nextInstanceOfDayInMonth(
      dayOfMonth: dayOfMonth,
      hour: hour,
      minute: minute,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static const int _pendingDebtIdBase = 1000000;
  static const int _reminderIdBase = 2000000;
  static const int _idRange = 900000;

  int _pendingDebtNotificationId(String debtId) {
    return _pendingDebtIdBase + (_stableHash(debtId) % _idRange);
  }

  int _reminderNotificationId(String debtId) {
    return _reminderIdBase + (_stableHash(debtId) % _idRange);
  }

  int _stableHash(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash & 0x7fffffff;
  }

  int _uniqueId() {
    final v = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    return v == 0 ? 1 : v;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfDayInMonth({
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var year = now.year;
    var month = now.month;

    var day = dayOfMonth.clamp(1, 31);
    final daysThisMonth = _daysInMonth(year, month);
    if (day > daysThisMonth) day = daysThisMonth;

    var scheduled = tz.TZDateTime(tz.local, year, month, day, hour, minute);

    if (!scheduled.isAfter(now)) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      day = dayOfMonth.clamp(1, 31);
      final daysNextMonth = _daysInMonth(year, month);
      if (day > daysNextMonth) day = daysNextMonth;
      scheduled = tz.TZDateTime(tz.local, year, month, day, hour, minute);
    }

    return scheduled;
  }

  int _daysInMonth(int year, int month) {
    final firstNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastThisMonth = firstNextMonth.subtract(const Duration(days: 1));
    return lastThisMonth.day;
  }

  tz.TZDateTime _coerceToFuture(tz.TZDateTime dateTime) {
    final now = tz.TZDateTime.now(tz.local);
    if (dateTime.isAfter(now)) return dateTime;
    return now.add(const Duration(seconds: 5));
  }

  Future<bool> _needsUpdate({
    required int id,
    required String title,
    required String body,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();
    final existing = pending.where((p) => p.id == id).toList();
    if (existing.isEmpty) return true;
    return existing.first.title != title || existing.first.body != body;
  }

  Future<String> _safeGetLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return 'UTC';
    }
  }

  void _setLocalTimezone(String timezoneName) {
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  String _formatMoney(double value) {
    return 'C\$ ${value.toStringAsFixed(2)}';
  }
}
