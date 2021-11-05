import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rentool/models/notification.dart';

class CloudMessagingServices {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  late final AndroidNotificationChannel channel;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// was `init()` called
  bool initialized = false;

  String? deviceToken;
  Future<void> init([BuildContext? context]) async {
    if (initialized) return;
    initialized = true;
    NotificationSettings settings = await _fcm.requestPermission();

    // Initialize flutterLocalNotificationsPlugin
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = IOSInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create and add the channel
    channel = AndroidNotificationChannel(
      // id
      'tools_notifications_channel',
      // title
      context == null ? 'Tools Notifications' : AppLocalizations.of(context)!.tools_notifications,
      // description
      description: context == null
          ? 'This channel is used for tools notifications such as reciving a request, accepted request, or rent starting.'
          : AppLocalizations.of(context)!.tools_notifications_channel_desc,
    );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        deviceToken = await _fcm.getToken();
      } catch (_) {}
    }

    FirebaseMessaging.onMessage.listen((message) async {
      if (context != null) {
        final notification = RentoolNotification(
          message.hashCode.toString(),
          message.data['code'],
          message.data,
          false,
          DateTime.now(),
        );

        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          notification.getTitle(context),
          notification.getBody(context),
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        // Navigate to page?
        // set `isRead` to `true`
        print(
          '`onMessageOpenedApp` Notification: ${message.notification?.title ?? 'no Title'}, ${message.notification?.body ?? 'no body'}',
        );
        print('`onMessageOpenedApp`- Body: ${message.data}');
      },
    );
  }
}

Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  print(
      '`onMessage` Noti Gang: ${message.notification?.title ?? 'no Title'}, ${message.notification?.body ?? 'no body'}');
  print('`onBackgroundMessage`- Body: ${message.data}');
}
