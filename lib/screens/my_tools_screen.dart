import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/tool_tile.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

class MyToolsScreen extends StatefulWidget {
  const MyToolsScreen({Key? key}) : super(key: key);

  @override
  _MyToolsScreenState createState() => _MyToolsScreenState();
}

class _MyToolsScreenState extends State<MyToolsScreen> {
  /// is loading from Firestore?
  ///
  /// used to prevent multiple calls for Firestore.
  bool isLoading = false;

  /// there is no more docs other than the one loaded
  ///
  /// defaults to `false` and turns `true` when [_getTools()] doesn't return any docs
  bool noMoreDocs = false;
  List<Tool> tools = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getTools() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getUserTool(AuthServices.currentUid!, previousDoc: previousDoc);
    if (result.docs.isEmpty) {
      noMoreDocs = true;
    } else {
      for (var doc in result.docs) {
        final tool = Tool.fromJson((doc.data() as Map<String, dynamic>)..addAll({'id': doc.id}));
        tools.add(tool);
      }
      previousDoc = result.docs.last;
    }
    isLoading = false;
  }

  _refresh() {
    tools.clear();
    noMoreDocs = false;
    previousDoc = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myTools),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, '/newPost');
          setState(() {});
        },
      ),
      body: FutureBuilder(
        future: _getTools(),
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              itemCount: tools.length + 1,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                if (index >= tools.length) {
                  if (!noMoreDocs) {
                    _getTools().then((value) {
                      setState(() {});
                    });
                  }
                  return ListTile(
                    title: noMoreDocs ? null : const LinearProgressIndicator(),
                  );
                }

                final tool = tools[index];
                return ToolTile(
                  tool: tool,
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/post', arguments: tool);
                    setState(() {
                      if (result == 'Deleted') {
                        tools.remove(tool);
                      }
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
