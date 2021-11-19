import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/constants.dart';
import 'package:rentool/misc/misc.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/admin_panel_screen.dart';
import 'package:rentool/screens/my_notifications.dart';
import 'package:rentool/screens/my_requests.dart';
import 'package:rentool/screens/my_tools_screen.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/screens/search_screen.dart';
import 'package:rentool/screens/settings_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/compact_tool_tile.dart';
import 'package:rentool/widgets/logo_image.dart';
import 'package:rentool/widgets/rentool_search_bar.dart';
import 'package:rentool/widgets/user_listtile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _noMoreDocs = false;
  List<Tool> tools = [];

  @override
  void initState() {
    _getRandomDocs().then((value) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RentoolSearchAppBar(
        textFieldContoller: _searchController,
        onSubmitted: (value) async {
          if (value.trim().isEmpty) return;
          await Navigator.pushNamed(
            context,
            SearchScreen.routeName,
            arguments: value.trim(),
          );
          setState(() {
            _searchController.clear();
          });
        },
      ),
      // TODO invistigate opening the drawer causes auth stream to trigger
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: LogoImage.primary(),
              margin: EdgeInsets.zero,
            ),
            UserListTile(
              user: AuthServices.auth.currentUser!,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  UserScreen.routeName,
                  arguments: UserScreenArguments(uid: AuthServices.currentUid!),
                );
              },
            ),
            FutureBuilder(
              future: AuthServices.getIdTokenResult(),
              builder: (context, AsyncSnapshot<IdTokenResult?> snapshot) {
                AuthServices.isAdmin = snapshot.data?.claims?['admin'] == true;
                if (AuthServices.isAdmin) {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(AppLocalizations.of(context)!.admin_panel),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AdminPanelScreen.routeName);
                    },
                  );
                }
                return Container();
              },
            ),
            const Divider(height: 2),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(AppLocalizations.of(context)!.notifications),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(MyNotificationsScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded),
              title: Text(AppLocalizations.of(context)!.myRequests),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(MyRequestsScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: Text(AppLocalizations.of(context)!.myTools),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(MyToolsScreen.routeName);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(SettingsScreen.routeName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support),
              title: Text(AppLocalizations.of(context)!.support),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await launchUrl('mailto:$supportEmailAddress');
                } catch (e) {
                  await Future.delayed(const Duration(milliseconds: 300));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.couldnt_open_email_client),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.copy_email_address,
                        onPressed: () => Clipboard.setData(const ClipboardData(text: supportEmailAddress)),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WelcomeToRentool(),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                // TODO
                AppLocalizations.of(context)!.random_tools.toUpperCase(),
                style: Theme.of(context).textTheme.overline,
              ),
              const SizedBox(height: 7),
              _buildRandomToolsWrap(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomToolsWrap() {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      children: [
        for (var index = 0; index < tools.length; index++)
          Builder(
            // itemCount: tools.length,
            // separatorBuilder: (context, index) => const Divider(),
            builder: (context) {
              // If there is no objects and no more docs
              if (_noMoreDocs && tools.isEmpty) {
                return _buildEmptyWidget();
              }
              final i = index % tools.length;

              if (i >= tools.length) {
                if (!_noMoreDocs) {
                  // If at the end of the list and didn't reach the end of the list (!noMoreDocs)
                  // then call _getDocs() and setState when Done
                  _getRandomDocs().then((value) => setState(() {}));
                }
                // Show loading bar or empty if the end of the list was reached (noMoreDocs)
                return ListTile(
                  title: _noMoreDocs ? null : const LinearProgressIndicator(),
                );
              }
              final tool = tools[i];
              return CompactToolTile(
                tool: tool,
                onTap: () => Navigator.pushNamed(context, PostScreen.routeName, arguments: tool),
              );
            },
          ),
      ],
    );
  }

  Future<void> _getRandomDocs([numberOfDocs = 10]) async {
    if (tools.length >= 30) {
      _noMoreDocs = true;
      return;
    }
    if (_isLoading) return;
    _isLoading = true;

    var docs = <QueryDocumentSnapshot<Object?>>[];
    for (var i = 0; i < numberOfDocs; i++) {
      try {
        print('calling');
        final result = (await FirestoreServices.getRandomTool()).docs;
        if (!docs.any((element) => element.id == result.first.id)) {
          docs.addAll(result);
        }
      } catch (e, stack) {
        debugPrintStack(label: 'ERRRRROR $e');
      }
    }

    if (docs.isEmpty) {
      _noMoreDocs = true;
    } else {
      for (var doc in docs) {
        var data = doc.data();
        if (data is Map<String, dynamic>) {
          final tool = Tool.fromJson(data..addAll({'id': doc.id}));
          tools.add(tool);
        }
      }
    }
    _isLoading = false;
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Text('Empty'),
    );
  }
}

class WelcomeToRentool extends StatelessWidget {
  const WelcomeToRentool({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.welcome_to_rentool,
            style: Theme.of(context).textTheme.headline5?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primaryVariant,
                ),
          ),
          Text(
            AppLocalizations.of(context)!.offer_n_rent,
            style: Theme.of(context).textTheme.subtitle1?.copyWith(
                  color: Theme.of(context).colorScheme.primaryVariant,
                ),
          ),
        ],
      ),
    );
  }
}
