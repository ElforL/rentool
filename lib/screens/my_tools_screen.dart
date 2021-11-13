import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/edit_post_screen.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/tool_tile.dart';

class MyToolsScreen extends StatefulWidget {
  const MyToolsScreen({Key? key}) : super(key: key);

  static const routeName = '/myTools';

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
    setState(() {
      tools.clear();
      noMoreDocs = false;
      previousDoc = null;
    });
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
          if (!AuthServices.currentUser!.emailVerified) {
            showEmailNotVerifiedDialog(context);
            return;
          }
          if (FirestoreServices.hasId != true) {
            showIdMissingDialog(context);
            return;
          }
          if (FirestoreServices.hasCard != true) {
            showMissingCardDialog(context);
            return;
          }
          // if (FirestoreServices.cardPayouts != true) {
          //   showNoPayoutsDialog(context);
          //   return;
          // }
          await Navigator.pushNamed(context, EditPostScreen.routeNameNew);
          setState(() {});
        },
      ),
      body: FutureBuilder(
        future: _getTools(),
        builder: (context, snapshot) {
          if (noMoreDocs && tools.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: Icon(
                          Icons.build,
                          size: 70,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Icon(
                        Icons.do_not_disturb,
                        size: 150,
                        color: Colors.grey.shade800,
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.no_tools,
                    style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

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
                    final result = await Navigator.pushNamed(context, PostScreen.routeName, arguments: tool);
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
