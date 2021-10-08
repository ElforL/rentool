import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/disagreement_case.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/screens/request_screen.dart';
import 'package:rentool/screens/user_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/media_container.dart';
import 'package:rentool/widgets/note_box.dart';
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
    required this.onBackButtonPressed,
  }) : super(key: key);

  final DisagreementCase disagreementCase;
  final void Function()? onBackButtonPressed;

  @override
  _DisagreementCasePageState createState() => _DisagreementCasePageState();
}

class _DisagreementCasePageState extends State<DisagreementCasePage> {
  late final TextEditingController _descriptionContoller;
  ToolRequest? request;

  bool? toolDamaged;

  /// used to set the post button state when the decision fields change
  final buttonKey = GlobalKey();

  String? descriptionErrorText;

  @override
  void initState() {
    toolDamaged = widget.disagreementCase.resultIsToolDamaged;
    _descriptionContoller = TextEditingController(text: widget.disagreementCase.resultDescription);
    super.initState();
  }

  @override
  void dispose() {
    _descriptionContoller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.disagreementCase.id),
        leading: BackButton(
          onPressed: widget.onBackButtonPressed,
        ),
      ),
      body: ListView(
        children: [
          _buildCaseInfo(),
          const Divider(),
          ..._buildMedia(),
          const Divider(),
          ..._buildDecission(),
          // Free bottom space
          const SizedBox(height: 100),
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
            AppLocalizations.of(context)!.case_info,
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ColumnSeperatedText(
              first: AppLocalizations.of(context)!.case_id + ': ',
              second: widget.disagreementCase.id,
            ),
          ),
          InkWell(
            onTap: () {
              // Navigate to post screen
              // the post screen will call the tool's doc snapshot
              // so these temporary values will be updated.
              Navigator.of(context).pushNamed(
                PostScreen.routeName,
                arguments: Tool(
                  widget.disagreementCase.toolId,
                  widget.disagreementCase.ownerUid,
                  AppLocalizations.of(context)!.loading,
                  AppLocalizations.of(context)!.loading,
                  0,
                  0,
                  [],
                  AppLocalizations.of(context)!.loading,
                  false,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.tool_id + ': ',
                second: widget.disagreementCase.toolId,
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              if (request == null) {
                _showLoadingRequestDialog();
                final doc = await FirestoreServices.getToolRequest(
                    widget.disagreementCase.toolId, widget.disagreementCase.requestId);
                try {
                  request = ToolRequest.fromJson(doc.data()!..addAll({'id': doc.id}));
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(
                    RequestScreen.routeName,
                    arguments: RequestScreenArguments(request!, false),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  _showFailedLoadingRequestDialog();
                }
              } else {
                Navigator.of(context).pushNamed(
                  RequestScreen.routeName,
                  arguments: RequestScreenArguments(request!, false),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.request_id + ': ',
                second: widget.disagreementCase.requestId,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                UserScreen.routeName,
                arguments: UserScreenArguments(uid: widget.disagreementCase.ownerUid),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.owner_uid + ': ',
                second: widget.disagreementCase.ownerUid,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                UserScreen.routeName,
                arguments: UserScreenArguments(uid: widget.disagreementCase.renterUid),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.renter_uid + ': ',
                second: widget.disagreementCase.renterUid,
              ),
            ),
          ),
          InkWell(
            onTap: widget.disagreementCase.admin == null
                ? null
                : () {
                    Navigator.of(context).pushNamed(
                      UserScreen.routeName,
                      arguments: UserScreenArguments(uid: widget.disagreementCase.admin),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ColumnSeperatedText(
                first: AppLocalizations.of(context)!.assigned_admin + ': ',
                second: widget.disagreementCase.admin ?? AppLocalizations.of(context)!.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMedia() {
    return [
      ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(
          AppLocalizations.of(context)!.media,
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          AppLocalizations.of(context)!.before_in_delivery_meeting,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      _buildMediaExpansionTile(
        Text(AppLocalizations.of(context)!.owner_possession),
        widget.disagreementCase.ownerMedia,
        subtitle: widget.disagreementCase.ownerMedia.isEmpty ? _emptySubtitle() : null,
      ),
      _buildMediaExpansionTile(
        Text(AppLocalizations.of(context)!.renter_possession),
        widget.disagreementCase.renterMedia,
        subtitle: widget.disagreementCase.ownerMedia.isEmpty ? _emptySubtitle() : null,
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          AppLocalizations.of(context)!.after_in_return_meeting,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      _buildMediaExpansionTile(
        Text(AppLocalizations.of(context)!.owner_possession),
        widget.disagreementCase.ownerMedia,
        subtitle: widget.disagreementCase.ownerMedia.isEmpty ? _emptySubtitle() : null,
      ),
      _buildMediaExpansionTile(
        Text(AppLocalizations.of(context)!.renter_possession),
        widget.disagreementCase.renterMedia,
        subtitle: widget.disagreementCase.ownerMedia.isEmpty ? _emptySubtitle() : null,
      ),
    ];
  }

  Text _emptySubtitle() {
    return Text(
      AppLocalizations.of(context)!.empty,
      style: Theme.of(context).textTheme.caption,
    );
  }

  Theme _buildMediaExpansionTile(Widget title, List<String> mediaUrls, {Widget? subtitle}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        maintainState: true,
        textColor: Theme.of(context).colorScheme.onSurface,
        iconColor: Theme.of(context).colorScheme.onSurface,
        title: title,
        subtitle: subtitle,
        children: [
          SizedBox(
            height: 200,
            child: mediaUrls.isNotEmpty
                ? ListView(
                    addAutomaticKeepAlives: true,
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var url in mediaUrls)
                        MediaContainer(
                          showDismiss: false,
                          mediaURL: url,
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported_outlined,
                        size: 70,
                      ),
                      Text(AppLocalizations.of(context)!.empty, style: Theme.of(context).textTheme.headline6),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildDecission() {
    return [
      ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(
          AppLocalizations.of(context)!.decision,
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
      const SizedBox(height: 10),
      ListTile(
        title: Text(
          AppLocalizations.of(context)!.was_tool_damaged,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.topStart,
          child: DropdownButton<bool?>(
            value: toolDamaged,
            hint: Text(AppLocalizations.of(context)!.select),
            items: <DropdownMenuItem<bool?>>[
              DropdownMenuItem(
                value: true,
                child: Text(AppLocalizations.of(context)!.damaged(false)),
              ),
              DropdownMenuItem(
                value: false,
                child: Text(AppLocalizations.of(context)!.not_damaged(false)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                toolDamaged = value;
              });
            },
          ),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.topStart,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(15),
          child: NoteBox(
            text: AppLocalizations.of(context)!.write_desc_in_ar_and_en,
            icon: Icons.error,
          ),
        ),
      ),
      ListTile(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            AppLocalizations.of(context)!.description,
            style: Theme.of(context).textTheme.subtitle1!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.enter_justification_for_decision,
                errorText: descriptionErrorText,
              ),
              onChanged: (desc) {
                // Clear the error once the user starts typing
                if (descriptionErrorText != null) {
                  setState(() {
                    descriptionErrorText = null;
                  });
                }
                // Update the post button state
                // This will enable/disable the button based on [didChange]
                buttonKey.currentState!.setState(() {});
              },
              controller: _descriptionContoller,
              minLines: 10,
              maxLines: null,
            ),
          ),
        ),
      ),
      _PostDecisionButton(
        key: buttonKey,
        context: context,
        didChange: () => didChange,
        onPressed: isUserPartOfCase() || toolDamaged == null
            ? null
            : () async {
                if (_descriptionContoller.text.trim().isEmpty) {
                  setState(() {
                    descriptionErrorText = AppLocalizations.of(context)!.you_cant_leave_this_empty;
                  });
                } else {
                  await widget.disagreementCase.pushResult(
                    toolDamaged!,
                    _descriptionContoller.text.trim(),
                  );
                  setState(() {});
                }
              },
      ),
    ];
  }

  bool get didChange {
    final damageChanged = toolDamaged != widget.disagreementCase.resultIsToolDamaged;
    final descChanged = _descriptionContoller.text.trim() != (widget.disagreementCase.resultDescription ?? '');
    return damageChanged || descChanged;
  }

  bool isUserPartOfCase() {
    final uid = AuthServices.currentUid;
    return uid == widget.disagreementCase.renterUid || uid == widget.disagreementCase.ownerUid;
  }

  void _showLoadingRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: AlertDialog(
          title: Text(AppLocalizations.of(context)!.loading_request_info),
          content: const LinearProgressIndicator(),
        ),
      ),
    );
  }

  void _showFailedLoadingRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.error_loading_request_info),
        content: Text(AppLocalizations.of(context)!.error_loading_request_info_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok.toUpperCase()),
          )
        ],
      ),
    );
  }
}

class _PostDecisionButton extends StatefulWidget {
  const _PostDecisionButton({
    Key? key,
    required this.context,
    required this.didChange,
    required this.onPressed,
  }) : super(key: key);

  final BuildContext context;
  final bool Function() didChange;
  final void Function()? onPressed;

  @override
  State<_PostDecisionButton> createState() => _PostDecisionButtonState();
}

class _PostDecisionButtonState extends State<_PostDecisionButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: AlignmentDirectional.topStart,
      child: ElevatedButton(
        child: Text(AppLocalizations.of(context)!.post_decision.toUpperCase()),
        onPressed: !widget.didChange() ? null : widget.onPressed,
      ),
    );
  }
}

class ColumnSeperatedText extends StatelessWidget {
  const ColumnSeperatedText({
    Key? key,
    required this.first,
    required this.second,
    this.firstStyle,
    this.secondStyle,
  }) : super(key: key);

  final String first;
  final String second;
  final TextStyle? firstStyle;
  final TextStyle? secondStyle;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyText2,
        children: <TextSpan>[
          TextSpan(text: first, style: firstStyle ?? const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: second, style: secondStyle),
        ],
      ),
    );
  }
}
