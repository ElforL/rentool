import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  /// is loading from Firestore?
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;
  List<ToolRequest> requests = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getRequests() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getUserRequests(AuthServices.currentUid!, previousDoc: previousDoc);
    for (var doc in result.docs) {
      final request = ToolRequest.fromJson(doc.data()..addAll({'id': doc.id}));
      requests.add(request);
    }
    previousDoc = result.docs.last;
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myRequests),
      ),
      body: FutureBuilder(
        future: _getRequests(),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              if (index >= requests.length) {
                _getRequests().then((value) {
                  setState(() {});
                });
                return const ListTile(
                  title: LinearProgressIndicator(),
                );
              }
              final request = requests[index];
              return ListTile(
                title: FutureBuilder(
                  future: FirestoreServices.getTool(request.toolID),
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Object?>> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
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
                subtitle: Text(
                  '${request.numOfDays} ${AppLocalizations.of(context)!.days}',
                ),
                onTap: () {
                  // TODO navigate to request screen.
                },
              );
            },
          );
        },
      ),
    );
  }
}
