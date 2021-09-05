import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rentool/widgets/notification_tile.dart';

class CloudMessagingServices {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// was `init()` called
  bool initialized = false;

  String? deviceToken;
  Future<void> init([BuildContext? context]) async {
    if (initialized) return;
    initialized = true;
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      deviceToken = await _fcm.getToken();
    }

    FirebaseMessaging.onMessage.listen((message) async {
      if (context != null) {
        try {
          const duration = Duration(seconds: 5);
          final entry = OverlayEntry(
            builder: (context) {
              return Align(
                alignment: Alignment.topCenter,
                child: NotificationTile(
                  visibleDuration: duration,
                  data: message.data,
                ),
              );
            },
          );
          Overlay.of(context)!.insert(entry);
          await Future.delayed(duration);
          entry.remove();
        } on ArgumentError catch (e) {
          debugPrint(
            "failed to show notification tile. this usually happens if `NotificationTile` couldn't parse the notification code\n${e.toString()}",
          );
        }
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
