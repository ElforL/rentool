import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/disagreement_case.dart';
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
          WillPopScope(
            onWillPop: () {
              _setCase(null);
              return Future.value(false);
            },
            child: DisagreementCasePage(
              disCase: currentCase!,
            ),
          ),
      ],
    );
  }
}

class DisagreementCasesListPage extends StatelessWidget {
  const DisagreementCasesListPage({
    Key? key,
    required this.onTileTap,
  }) : super(key: key);

  final void Function(DisagreementCase disagreementCase)? onTileTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.disagreement_cases),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
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
      onTap: onTileTap == null ? null : () => onTileTap!(disCase),
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

class DisagreementCasePage extends StatefulWidget {
  const DisagreementCasePage({
    Key? key,
    required this.disagreementCase,
  }) : super(key: key);

  final DisagreementCase disagreementCase;

  @override
  _DisagreementCasePageState createState() => _DisagreementCasePageState();
}

class _DisagreementCasePageState extends State<DisagreementCasePage> {
  @override
  void dispose() {
    //TODO contoller dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.disagreementCase.id),
      ),
    );
  }
}
