import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/banned_ids_admin_page.dart';
import 'package:rentool/screens/banned_users_admin_page.dart';
import 'package:rentool/screens/disagreement_cases_admin_page.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/widgets/rentool_circle_avatar.dart';

/// The panel for admins to manage disagreement cases, banned users... etc.
///
/// Could pass [AdminPanelPage] as argument to the route when pushing to the Navigator.
class AdminPanelScreen extends StatefulWidget {
  AdminPanelScreen({Key? key})
      : assert(AuthServices.isAdmin),
        super(key: key);

  static const routeName = '/admin';

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool argsRead = false;
  AdminPanelPage currentPage = AdminPanelPage.disagreementsCases;

  @override
  Widget build(BuildContext context) {
    // Read args
    _readArgs(context);

    final size = MediaQuery.of(context).size;
    bool drawerInBody = size.width >= 670;

    final drawer = Row(children: [
      Drawer(
        elevation: 0,
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RentoolCircleAvatar.firebaseUser(user: AuthServices.currentUser!),
                  const SizedBox(height: 10),
                  if (AuthServices.currentUser?.displayName != null) Text(AuthServices.currentUser!.displayName!),
                ],
              ),
            ),
            _buildListTile(AdminPanelPage.disagreementsCases, drawerInBody),
            _buildListTile(AdminPanelPage.bannedUsers, drawerInBody),
            _buildListTile(AdminPanelPage.bannedIds, drawerInBody),
          ],
        ),
      ),
      const VerticalDivider(width: 1),
    ]);

    Widget body;

    switch (currentPage) {
      case AdminPanelPage.disagreementsCases:
        body = const DisagreementCasesAdminPage();
        break;
      case AdminPanelPage.bannedUsers:
        body = const BannedUsersAdminPage();
        break;
      case AdminPanelPage.bannedIds:
        body = const BannedIdsAdminPage();
        break;
      default:
        throw Exception('Invalid AdminPanelPage: $currentPage');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.admin_panel),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 4,
      ),
      drawer: drawerInBody ? null : drawer,
      body: drawerInBody
          ? Row(
              children: [
                drawer,
                Expanded(
                  child: body,
                ),
              ],
            )
          : body,
    );
  }

  Widget _buildListTile(AdminPanelPage page, bool drawerInBody) {
    IconData icon;
    String titleText;
    switch (page) {
      case AdminPanelPage.disagreementsCases:
        icon = Icons.gavel_rounded;
        titleText = AppLocalizations.of(context)!.disagreement_cases;
        break;
      case AdminPanelPage.bannedUsers:
        icon = Icons.person;
        titleText = AppLocalizations.of(context)!.banned_users;
        break;
      case AdminPanelPage.bannedIds:
        icon = Icons.badge;
        titleText = AppLocalizations.of(context)!.banned_ids;
        break;
      default:
        throw Exception('Invalid AdminPanelPage: $page');
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(titleText),
      onTap: () {
        if (!drawerInBody) Navigator.pop(context);
        _setPage(page);
      },
      selectedTileColor: currentPage == page ? Theme.of(context).colorScheme.primary.withAlpha(40) : null,
      selected: currentPage == page,
    );
  }

  void _setPage(AdminPanelPage page) => setState(() => currentPage = page);

  void _readArgs(BuildContext context) {
    if (!argsRead) {
      argsRead = true;
      var args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is AdminPanelPage) {
        _setPage(args);
      }
    }
  }
}

enum AdminPanelPage {
  disagreementsCases,
  bannedUsers,
  bannedIds,
}

extension ParseToString on AdminPanelPage {
  String toShortString() {
    return toString().split('.').last;
  }
}
