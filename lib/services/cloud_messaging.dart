import 'package:firebase_messaging/firebase_messaging.dart';

class CloudMessagingServices {
  FirebaseMessaging _fcm = FirebaseMessaging.instance;

  CloudMessagingServices();

  Future<void> init() async {
    var token = await _fcm.getToken();
    print(token);
    FirebaseMessaging.onMessage.listen((message) {
      print('`onMessage` Noti Gang: ${message.notification.title}, ${message.notification.body}');
      print('`onMessage`- Body: ${message.data}');
    });

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        print('`onMessageOpenedApp` Noti Gang: ${message.notification.title}, ${message.notification.body}');
        print('`onMessageOpenedApp`- Body: ${message.data}');
      },
    );
  }
}

Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  print('`onBackgroundMessage` Noti Gang: ${message.notification.title}, ${message.notification.body}');
  print('`onBackgroundMessage`- Body: ${message.data}');
}
