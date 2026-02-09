import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  LocalNotification._();

  static final LocalNotification instance = LocalNotification._();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  displayNotification(String title, String body, String payload) async {
    late NotificationDetails notificationDetails;
    if (Platform.isAndroid) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('your channel id', 'your channel name',
              channelDescription: 'your channel description',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker');
      notificationDetails =
          const NotificationDetails(android: androidNotificationDetails);
    } else if (Platform.isIOS) {
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );
      notificationDetails =
          const NotificationDetails(iOS: iosNotificationDetails);
    }
    await plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
