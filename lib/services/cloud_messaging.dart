import 'package:firebase_messaging/firebase_messaging.dart';

class CloudMessagingServices {
  FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String deviceToken;
  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      deviceToken = await _fcm.getToken();
    }

    FirebaseMessaging.onMessage.listen((message) {
      // TODO show in-app notification
      print(
        '`onMessage` Noti Gang: ${message.notification?.title ?? 'no Title'}, ${message.notification?.body ?? 'no body'}',
      );
      print('`onMessage`- Body: ${message.data}');
    });

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        // Navigate to page?
        // set `isRead` to `true`
        print(
            '`onMessage` Noti Gang: ${message.notification?.title ?? 'no Title'}, ${message.notification?.body ?? 'no body'}');
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

// TODO set `NotificationType`
enum NotificationType {
  normal,
}
