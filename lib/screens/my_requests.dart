import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  static const routeName = '/myRequests';

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  /// is loading from Firestore?
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getRequests()] doesn't return any docs
  bool noMoreDocs = false;
  List<ToolRequest> requests = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getRequests() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getUserRequests(AuthServices.currentUid!, previousDoc: previousDoc);
    if (result.docs.isEmpty) {
      noMoreDocs = true;
    } else {
      for (var doc in result.docs) {
        final request = ToolRequest.fromJson(doc.data());
        requests.add(request);
      }
      previousDoc = result.docs.last;
    }
    isLoading = false;
  }

  _refresh() {
    setState(() {
      requests.clear();
      noMoreDocs = false;
      previousDoc = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myRequests),
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
        future: _getRequests(),
        builder: (context, snapshot) {
          if (noMoreDocs && requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 70,
                        color: Colors.grey.shade700,
                      ),
                      Icon(
                        Icons.do_not_disturb,
                        size: 150,
                        color: Colors.grey.shade800,
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.no_requests_sent,
                    style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              itemCount: requests.length + 1,
              itemBuilder: (context, index) {
                if (index >= requests.length) {
                  if (!noMoreDocs) {
                    _getRequests().then((value) {
                      setState(() {});
                    });
                  }
                  return ListTile(
                    title: noMoreDocs ? null : const LinearProgressIndicator(),
                  );
                }
                final request = requests[index];
                return ListTile(
                  title: FutureBuilder(
                    future: FirestoreServices.getTool(request.toolID),
                    builder: (context, AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
                      if (snapshot.connectionState != ConnectionState.done && snapshot.data == null) {
                        return const LinearProgressIndicator();
                      }
                      final tool = Tool.fromJson(
                        (snapshot.data!.data() as Map<String, dynamic>)..addAll({'id': snapshot.data!.id}),
                      );
                      return Text(
                        tool.name,
                      );
                    },
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.days_plural(request.numOfDays)),
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      RequestScreen.routeName,
                      arguments: RequestScreenArguments(request, false),
                    );
                    setState(() {});
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
