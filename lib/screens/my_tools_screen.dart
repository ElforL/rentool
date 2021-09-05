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
  List<Tool> tools = [];
  DocumentSnapshot<Object?>? previousDoc;

  Future<void> _getTools() async {
    if (isLoading) return;
    isLoading = true;
    final result = await FirestoreServices.getUserTool(AuthServices.currentUid!, previousDoc: previousDoc);
    for (var doc in result.docs) {
      final tool = Tool.fromJson((doc.data() as Map<String, dynamic>)..addAll({'id': doc.id}));
      tools.add(tool);
    }
    previousDoc = result.docs.last;
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myTools),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, '/newPost');
          setState(() {});
        },
      ),
      body: FutureBuilder(
        future: _getTools(),
        builder: (context, snapshot) {
          return ListView.separated(
            primary: false,
            itemCount: tools.length + 1,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index >= tools.length) {
                _getTools().then((value) {
                  setState(() {});
                });
                return const ListTile();
              }

              final tool = tools[index];
              return ToolTile(
                tool: tool,
                onTap: () async {
                  await Navigator.pushNamed(context, '/post', arguments: tool);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
