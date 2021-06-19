import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({Key key, this.tool}) : super(key: key);

  final Tool tool;

  @override
  _RequestsListScreenState createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  List<ToolRequest> list;
  DocumentSnapshot _lastDoc;

  @override
  void initState() {
    list = [];
    super.initState();
  }

  _getRequests() async {
    var res = await FirestoreServices.fetchToolRequests(widget.tool.id, previousDoc: _lastDoc);
    _lastDoc = res.docs.last;
    for (var doc in res.docs) {
      var request = ToolRequest.fromJson(doc.data());
      list.add(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Requests for ${widget.tool.name}'),
      ),
      body: FutureBuilder(
        future: _getRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (list.length == 0) {
            return Center(
              child: Text('No Requests'),
            );
          }
          return ListView.builder(
            itemCount: (list.length > 10 ? 10 : list.length) * 2,
            itemBuilder: (context, index) {
              if (index % 2 != 0) return Divider();
              return RequestTile(
                request: list[index ~/ 2],
              );
            },
          );
        },
      ),
    );
  }
}

class RequestTile extends StatefulWidget {
  const RequestTile({Key key, @required this.request}) : super(key: key);

  final ToolRequest request;

  @override
  _RequestTileState createState() => _RequestTileState();
}

class _RequestTileState extends State<RequestTile> {
  var subtitle = Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: () {
          // FirestoreServices.acceptRequest(widget.request.renterUID);
        },
        child: Text('ACCEPT'),
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
      ),
      SizedBox(width: 20),
      ElevatedButton(
        onPressed: () {
          // FirestoreServices.rejectRequest(widget.request.renterUID);
        },
        child: Text('REJECT'),
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
      )
    ],
  );

  bool _show = false;

  void _tap() {
    setState(() {
      _show = !_show;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(_show);
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Text(widget.request.numOfDays.toString()),
      ),
      subtitle: AnimatedSize(
        duration: Duration(milliseconds: 300),
        child: _show ? subtitle : Container(),
      ),
      onTap: _tap,
    );
  }
}
