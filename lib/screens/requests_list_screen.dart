import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({Key? key}) : super(key: key);

  @override
  _RequestsListScreenState createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  late Tool tool;

  late List<ToolRequest> list;
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    list = [];
    super.initState();
  }

  _getRequests() async {
    var res = await FirestoreServices.fetchToolRequests(tool.id, previousDoc: _lastDoc);
    _lastDoc = res.docs.last;
    for (var doc in res.docs) {
      var request = ToolRequest.fromJson(doc.data()..addAll({'id': doc.id}));
      list.add(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    tool = ModalRoute.of(context)!.settings.arguments as Tool;

    return Scaffold(
      appBar: AppBar(
        title: Text('Requests for ${tool.name}'),
      ),
      body: FutureBuilder(
        future: _getRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (list.isEmpty) {
            return const Center(
              child: Text('No Requests'),
            );
          }
          return ListView.builder(
            primary: false,
            itemCount: (list.length > 10 ? 10 : list.length) * 2,
            itemBuilder: (context, index) {
              if (index % 2 != 0) return const Divider();
              final request = list[index ~/ 2];
              return ListTile(
                title: Text('${request.numOfDays} ${AppLocalizations.of(context)!.days}'),
                subtitle: Text(request.renterUID),
                onTap: () => Navigator.of(context).pushNamed(
                  '/request',
                  arguments: RequestScreenArguments(request, true),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
