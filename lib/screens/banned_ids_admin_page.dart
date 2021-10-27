import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rentool/models/banned_id_entry.dart';
import 'package:rentool/screens/disagreement_case_page.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/pagination_listview.dart';

class BannedIdsAdminPage extends StatefulWidget {
  const BannedIdsAdminPage({
    Key? key,
  }) : super(key: key);

  @override
  _BannedIdsAdminPageState createState() => _BannedIdsAdminPageState();
}

class _BannedIdsAdminPageState extends State<BannedIdsAdminPage> {
  BannedIdEntry? bannedId;

  _setId(BannedIdEntry? bannedId) {
    setState(() => this.bannedId = bannedId);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: bannedId == null ? 0 : 1,
      children: [
        BannedIdsListPage(
          onTileTap: (bannedId) async {
            // The delay is purely visual
            // without it, the transition is too sudden
            await Future.delayed(const Duration(milliseconds: 150));
            _setId(bannedId);
          },
        ),
        if (bannedId != null)
          BannedIdPage(
            bannedId: bannedId!,
            onBackButtonPressed: () {
              _setId(null);
            },
          ),
      ],
    );
  }
}

class BannedIdsListPage extends StatelessWidget {
  const BannedIdsListPage({
    Key? key,
    this.onTileTap,
  }) : super(key: key);

  final void Function(BannedIdEntry bannedId)? onTileTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.banned_ids),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            // TODO add search
            onPressed: () {},
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const Divider(height: 0),
          Expanded(
            child: PaginationListView<BannedIdEntry>(
              getDocs: (previousDoc) => FirestoreServices.getBannedIds(previousDoc: previousDoc),
              fromDoc: (doc) => BannedIdEntry.fromJson(doc.data()),
              itemBuilder: tileBuilder,
              empty: _buildEmpty(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget tileBuilder(BuildContext context, BannedIdEntry bannedId, int index) {
    return ListTile(
      title: Text(bannedId.idNumber),
      subtitle: Text(
        '${AppLocalizations.of(context)!.assigned_admin}: ${bannedId.admin}',
      ),
      trailing: Text(DateFormat('dd/MM/yyyy').format(bannedId.banTime)),
      onTap: onTileTap == null ? null : () => onTileTap!(bannedId),
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
          Text(AppLocalizations.of(context)!.no_ids_are_banned),
        ],
      ),
    );
  }
}

class BannedIdPage extends StatefulWidget {
  const BannedIdPage({
    Key? key,
    required this.bannedId,
    this.onBackButtonPressed,
  }) : super(key: key);

  final BannedIdEntry bannedId;
  final void Function()? onBackButtonPressed;

  @override
  _BannedIdPageState createState() => _BannedIdPageState();
}

class _BannedIdPageState extends State<BannedIdPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bannedId.idNumber),
        leading: BackButton(
          onPressed: widget.onBackButtonPressed,
        ),
      ),
      body: ListView(
        children: [
          _buildCaseInfo(),
        ],
      ),
    );
  }

  Widget _buildCaseInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.ban_info,
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ColumnSeperatedText(
              first: AppLocalizations.of(context)!.id_number + ': ',
              second: widget.bannedId.idNumber,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ColumnSeperatedText(
              first: AppLocalizations.of(context)!.ban_time + ': ',
              second: DateFormat('dd/MM/yyyy - hh:mm a').format(widget.bannedId.banTime),
            ),
          ),
          InkWell(
            onTap: () {
              // Navigate to post screen
              // the post screen will call the tool's doc snapshot
              // so these temporary values will be updated.
              Navigator.of(context).pushNamed(
                UserScreen.routeName,
                arguments: UserScreenArguments(uid: widget.bannedId.uid),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.uid + ': ',
                second: widget.bannedId.uid,
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
                arguments: UserScreenArguments(uid: widget.bannedId.admin),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.assigned_admin + ': ',
                second: widget.bannedId.admin,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.the_reason + ': ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.bannedId.reason),
        ],
      ),
    );
  }
}
