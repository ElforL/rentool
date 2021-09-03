import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/notification.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

class MyNotificationsScreen extends StatefulWidget {
  const MyNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  /// is loading notifications from Firestore.
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;
  List<RentoolNotification> notifications = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getNotifications() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getNotifications(AuthServices.currentUid!, previousDoc: previousDoc);
    for (var doc in result.docs) {
      final notification = RentoolNotification.fromJson(doc.id, doc.data());
      notifications.add(notification);
    }
    previousDoc = result.docs.last;
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
      ),
      body: FutureBuilder(
        future: _getNotifications(),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: notifications.length + 1,
            itemBuilder: (context, index) {
              if (index >= notifications.length) {
                _getNotifications().then((value) {
                  setState(() {});
                });
                return const ListTile();
              }
              final notification = notifications[index];
              return ListTile(
                title: Text(
                  notification.getTitle(context),
                  style: notification.isRead ? null : const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  notification.getBody(context),
                  style: notification.isRead ? null : const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  setState(() {
                    notification.setIsRead();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
