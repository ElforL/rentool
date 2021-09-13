import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RentoolSearchAppBar(
        textFieldContoller: _searchController,
        onSubmitted: (value) async {
          await Navigator.pushNamed(
            context,
            '/search',
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
                  '/user',
                  arguments: UserScreenArguments(uid: AuthServices.currentUid!),
                );
              },
            ),
            const Divider(height: 2),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(AppLocalizations.of(context)!.notifications),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/myNotifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded),
              title: Text(AppLocalizations.of(context)!.myRequests),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/myRequests');
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: Text(AppLocalizations.of(context)!.myTools),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/myTools');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                // TODO navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.of(context)!.helpNSupport),
              onTap: () {
                Navigator.pop(context);
                // TODO navigate to help screen
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
                  titleText: 'Recived requests',
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
