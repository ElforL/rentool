import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/new_post_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/widgets/home_page/count_home_page_container.dart';
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
      appBar: RentoolSearchAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/newPost');
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Image.asset('assets/images/Logo/primary.png'),
              margin: EdgeInsets.zero,
            ),
            UserListTile(
              user: AuthServices.auth.currentUser!,
            ),
            const Divider(height: 2),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.notifications),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: Colors.amber.shade900,
                  ),
                ],
              ),
              title: Text(AppLocalizations.of(context)!.notifications),
              trailing: Text(
                '13',
                style: TextStyle(color: Colors.amber.shade900),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.inventory_rounded),
              title: Text(AppLocalizations.of(context)!.myOrders),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: Text(AppLocalizations.of(context)!.myTools),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(AppLocalizations.of(context)!.helpNSupport),
              onTap: () {},
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

  Container buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blue[300],
      ),
      width: 500,
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
