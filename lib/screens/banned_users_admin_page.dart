import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/banned_user_entry.dart';
import 'package:rentool/screens/disagreement_case_page.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/pagination_listview.dart';

class BannedUsersAdminPage extends StatefulWidget {
  const BannedUsersAdminPage({
    Key? key,
  }) : super(key: key);

  @override
  _BannedUsersAdminPageState createState() => _BannedUsersAdminPageState();
}

class _BannedUsersAdminPageState extends State<BannedUsersAdminPage> {
  BannedUserEntry? bannedUser;

  _setId(BannedUserEntry? bannedUser) {
    setState(() => this.bannedUser = bannedUser);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: bannedUser == null ? 0 : 1,
      children: [
        BannedUsersListPage(
          onTileTap: (bannedUserId) async {
            // The delay is purely visual
            // without it, the transition is too sudden
            await Future.delayed(const Duration(milliseconds: 150));
            _setId(bannedUserId);
          },
        ),
        if (bannedUser != null)
          BannedUserPage(
            bannedUser: bannedUser!,
            onBackButtonPressed: () {
              _setId(null);
            },
          ),
      ],
    );
  }
}

class BannedUsersListPage extends StatefulWidget {
  const BannedUsersListPage({
    Key? key,
    this.onTileTap,
  }) : super(key: key);

  final void Function(BannedUserEntry bannedUser)? onTileTap;

  @override
  State<BannedUsersListPage> createState() => _BannedUsersListPageState();
}

class _BannedUsersListPageState extends State<BannedUsersListPage> {
  bool isSearching = false;
  TextEditingController? _searchController;

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  Future<void> _search(String uid) async {
    try {
      showCircularLoadingIndicator(context);
      final doc = await FirestoreServices.getOneBannedUser(uid);
      if (!doc.exists || doc.data() == null) throw 'noData';
      final entry = BannedUserEntry.fromJson(doc.data()!);
      Navigator.pop(context);
      if (widget.onTileTap != null) widget.onTileTap!(entry);
    } catch (e) {
      Navigator.pop(context);
      print(e);
      showErrorDialog(
        context,
        content: e == 'noData' ? Text(AppLocalizations.of(context)!.no_results) : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                onSubmitted: _search,
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.uid),
              )
            : Text(AppLocalizations.of(context)!.banned_users),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              _searchController?.clear();
              setState(() {
                isSearching = !isSearching;
              });
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const Divider(height: 0),
          Expanded(
            child: PaginationListView<BannedUserEntry>(
              getDocs: (previousDoc) => FirestoreServices.getBannedUsers(previousDoc: previousDoc),
              fromDoc: (doc) => BannedUserEntry.fromJson(doc.data()),
              itemBuilder: tileBuilder,
              empty: _buildEmpty(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO
        },
      ),
    );
  }

  Widget tileBuilder(BuildContext context, BannedUserEntry bannedUser, int index) {
    return ListTile(
      title: Text(bannedUser.uid),
      subtitle: Text(
        '${AppLocalizations.of(context)!.assigned_admin}: ${bannedUser.admin}',
      ),
      trailing: Text(DateFormat('dd/MM/yyyy').format(bannedUser.banTime)),
      onTap: widget.onTileTap == null ? null : () => widget.onTileTap!(bannedUser),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height / 1.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_emotions_outlined,
            size: 100,
          ),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context)!.no_users_are_banned),
        ],
      ),
    );
  }
}

class BannedUserPage extends StatefulWidget {
  const BannedUserPage({
    Key? key,
    required this.bannedUser,
    this.onBackButtonPressed,
  }) : super(key: key);

  final BannedUserEntry bannedUser;
  final void Function()? onBackButtonPressed;

  @override
  _BannedUserPageState createState() => _BannedUserPageState();
}

class _BannedUserPageState extends State<BannedUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bannedUser.uid),
        leading: BackButton(
          onPressed: widget.onBackButtonPressed,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: _banInfo(),
      ),
    );
  }

  List<Widget> _banInfo() {
    return [
      Text(
        AppLocalizations.of(context)!.ban_info,
        style: Theme.of(context).textTheme.headline6,
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ColumnSeperatedText(
          first: AppLocalizations.of(context)!.ban_time + ': ',
          second: DateFormat('dd/MM/yyyy - hh:mm a').format(widget.bannedUser.banTime),
        ),
      ),
      InkWell(
        onTap: () {
          // Navigate to post screen
          // the post screen will call the tool's doc snapshot
          // so these temporary values will be updated.
          Navigator.of(context).pushNamed(
            UserScreen.routeName,
            arguments: UserScreenArguments(uid: widget.bannedUser.uid),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ColumnSeperatedText(
            first: AppLocalizations.of(context)!.uid + ': ',
            second: widget.bannedUser.uid,
          ),
        ),
      ),
      InkWell(
        onTap: () {
          // Navigate to post screen
          // the post screen will call the tool's doc snapshot
          // so these temporary values will be updated.
          Navigator.of(context).pushNamed(
            UserScreen.routeName,
            arguments: UserScreenArguments(uid: widget.bannedUser.admin),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ColumnSeperatedText(
            first: AppLocalizations.of(context)!.assigned_admin + ': ',
            second: widget.bannedUser.admin,
          ),
        ),
      ),
      Text(
        AppLocalizations.of(context)!.the_reason + ': ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(widget.bannedUser.reason),
    ];
  }
}
