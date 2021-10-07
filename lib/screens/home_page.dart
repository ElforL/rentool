import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/admin_panel_screen.dart';
import 'package:rentool/screens/my_notifications.dart';
import 'package:rentool/screens/my_requests.dart';
import 'package:rentool/screens/my_tools_screen.dart';
import 'package:rentool/screens/search_screen.dart';
import 'package:rentool/screens/settings_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/widgets/home_page/count_home_page_container.dart';
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
          await Navigator.pushNamed(
            context,
            SearchScreen.routeName,
            arguments: value,
          );
          setState(() {
            _searchController.clear();
          });
        },
      ),
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
              future: AuthServices.auth.currentUser?.getIdTokenResult(),
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
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              children: const [
                CountHomePageContainer(
                  titleText: 'Tools rented',
                  subtitle: '3',
                ),
                CountHomePageContainer(
                  titleText: 'Received requests',
                  subtitle: '12',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              child: Text(AppLocalizations.of(context)!.offeredTools),
            ),
          ],
        ),
      ),
    );
  }
}
