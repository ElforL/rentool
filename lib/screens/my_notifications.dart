import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rentool/models/notification.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/big_icons.dart';

class MyNotificationsScreen extends StatefulWidget {
  const MyNotificationsScreen({Key? key}) : super(key: key);

  static const routeName = '/myNotifications';

  @override
  State<MyNotificationsScreen> createState() => _MyNotificationsScreenState();
}

class _MyNotificationsScreenState extends State<MyNotificationsScreen> {
  /// is loading notifications from Firestore.
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getNotifications()] doesn't return any docs
  bool noMoreDocs = false;
  List<RentoolNotification> notifications = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getNotifications() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getNotifications(AuthServices.currentUid!, previousDoc: previousDoc);
    if (result.docs.isEmpty) {
      noMoreDocs = true;
    } else {
      for (var doc in result.docs) {
        final notification = RentoolNotification.fromJson(doc.id, doc.data());
        notifications.add(notification);
      }
      previousDoc = result.docs.last;
    }
    isLoading = false;
  }

  _refresh() {
    setState(() {
      notifications.clear();
      noMoreDocs = false;
      previousDoc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(AppLocalizations.of(context)!.refresh),
                onTap: () => _refresh(),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder(
        future: _getNotifications(),
        builder: (context, snapshot) {
          if (noMoreDocs && notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BigIcon(
                    icon: Icons.notifications_off_outlined,
                    color: Colors.grey.shade700,
                  ),
                  Text(
                    AppLocalizations.of(context)!.no_notifications,
                    style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              itemCount: notifications.length + 1,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                if (index >= notifications.length) {
                  if (!noMoreDocs) {
                    _getNotifications().then((value) {
                      setState(() {});
                    });
                  }
                  return ListTile(
                    title: noMoreDocs ? null : const LinearProgressIndicator(),
                  );
                }
                final notification = notifications[index];
                return ListTile(
                  trailing: Text(
                    DateFormat('h:mm a\ndd/MM/yyyy').format(notification.time.toLocal()),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.overline,
                  ),
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
            ),
          );
        },
      ),
    );
  }
}
