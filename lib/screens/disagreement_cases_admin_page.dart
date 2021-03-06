import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/disagreement_case.dart';
import 'package:rentool/screens/disagreement_case_page.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/pagination_listview.dart';

class DisagreementCasesAdminPage extends StatefulWidget {
  const DisagreementCasesAdminPage({Key? key}) : super(key: key);

  @override
  _DisagreementCasesAdminPageState createState() => _DisagreementCasesAdminPageState();
}

class _DisagreementCasesAdminPageState extends State<DisagreementCasesAdminPage> {
  DisagreementCase? currentCase;

  _setCase(DisagreementCase? newCase) {
    setState(() => currentCase = newCase);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentCase == null ? 0 : 1,
      children: [
        DisagreementCasesListPage(
          onTileTap: (disagreementCase) async {
            // The delay is purely visual
            // without it, the transition is too sudden
            await Future.delayed(const Duration(milliseconds: 150));
            _setCase(disagreementCase);
          },
        ),
        if (currentCase != null)
          DisagreementCasePage(
            disagreementCase: currentCase!,
            onBackButtonPressed: () {
              _setCase(null);
            },
          ),
      ],
    );
  }
}

class DisagreementCasesListPage extends StatefulWidget {
  const DisagreementCasesListPage({
    Key? key,
    required this.onTileTap,
  }) : super(key: key);

  final void Function(DisagreementCase disagreementCase)? onTileTap;

  @override
  State<DisagreementCasesListPage> createState() => _DisagreementCasesListPageState();
}

class _DisagreementCasesListPageState extends State<DisagreementCasesListPage> {
  bool _isSearching = false;
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

  Future<void> _search(String id) async {
    try {
      showCircularLoadingIndicator(context);
      final doc = await FirestoreServices.getOneDisagreemtnCase(id);
      if (!doc.exists || doc.data() == null) throw 'noData';
      final entry = DisagreementCase.fromJson(doc.data()!);

      // Pop loading indicator
      Navigator.pop(context);
      if (widget.onTileTap != null) widget.onTileTap!(entry);
    } catch (e, stacktrace) {
      // Pop loading indicator
      Navigator.pop(context);

      debugPrintStack(label: e.toString(), stackTrace: stacktrace);
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onSubmitted: _search,
                decoration: InputDecoration(hintText: AppLocalizations.of(context)!.disagreementCaseID),
              )
            : Text(AppLocalizations.of(context)!.disagreement_cases),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              _searchController?.clear();
              setState(() {
                _isSearching = !_isSearching;
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
            child: PaginationListView<DisagreementCase>(
              getDocs: (previousDoc) => FirestoreServices.getDisagreemtnCases(previousDoc: previousDoc),
              fromDoc: (doc) => DisagreementCase.fromJson(doc.data(), id: doc.id),
              itemBuilder: tileBuilder,
              empty: _buildEmpty(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget tileBuilder(BuildContext context, DisagreementCase disCase, int index) {
    return ListTile(
      isThreeLine: true,
      title: Text(disCase.id),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${AppLocalizations.of(context)!.tool_id}: ${disCase.toolId}'),
          Text(
            '${AppLocalizations.of(context)!.assigned_admin}: ${disCase.admin ?? AppLocalizations.of(context)!.none}',
          ),
        ],
      ),
      trailing: Text(DateFormat('dd/MM/yyyy').format(disCase.timeCreated)),
      onTap: widget.onTileTap == null ? null : () => widget.onTileTap!(disCase),
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
          Text(AppLocalizations.of(context)!.everyone_is_happy),
          Text(AppLocalizations.of(context)!.no_disagreement_cases),
        ],
      ),
    );
  }
}
