import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationTile extends StatefulWidget {
  const NotificationTile({
    Key? key,
    required this.visibleDuration,
    required this.data,
    this.onDismissed,
  }) : super(key: key);

  final Duration visibleDuration;
  final Map<String, dynamic> data;
  final Function? onDismissed;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forward();

  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void dismiss() {
    if (widget.onDismissed != null) widget.onDismissed!();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(widget.visibleDuration - const Duration(milliseconds: 500)).then((value) => _controller.reverse());
    assert(widget.data['code'] != null);
    final titleString = getTitle(widget.data['code']);
    final bodyString = getBody(widget.data['code'], widget.data);
    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
        child: Dismissible(
          key: ValueKey(widget.data['code']),
          child: Material(
            borderRadius: BorderRadius.circular(2),
            color: Colors.blue,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              title: Text(
                titleString,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                bodyString,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              trailing: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getTitle(String code) {
    switch (code) {
      case 'REQ_REC':
        return AppLocalizations.of(context)!.title_REQ_REC;
      case 'REQ_ACC':
        return AppLocalizations.of(context)!.title_REQ_ACC;
      case 'REQ_DEL':
        return AppLocalizations.of(context)!.title_REQ_DEL;
      case 'REN_START':
        return AppLocalizations.of(context)!.title_REN_START;
      case 'REN_END':
        return AppLocalizations.of(context)!.title_REN_END;
      case 'DC_DAM':
        return AppLocalizations.of(context)!.title_DC_DAM;
      case 'DC_NDAM':
        return AppLocalizations.of(context)!.title_DC_NDAM;
      default:
        throw ArgumentError("Code doesn't match any notification code: $code");
    }
  }

  String getBody(String code, Map<String, dynamic> data) {
    switch (code) {
      case 'REQ_REC':
        return AppLocalizations.of(context)!.body_REQ_REC(data['toolName'], data['renterName']);
      case 'REQ_ACC':
        return AppLocalizations.of(context)!.body_REQ_ACC(data['toolName']);
      case 'REQ_DEL':
        return AppLocalizations.of(context)!.body_REQ_DEL(data['toolName']);
      case 'REN_START':
        return AppLocalizations.of(context)!.body_REN_START(data['toolName'], data['otherUserName']);
      case 'REN_END':
        return AppLocalizations.of(context)!.body_REN_END(data['toolName'], data['otherUserName']);
      case 'DC_DAM':
        return AppLocalizations.of(context)!.body_DC_DAM(data['toolName']);
      case 'DC_NDAM':
        return AppLocalizations.of(context)!.body_DC_NDAM(data['toolName']);
      default:
        throw ArgumentError("Code doesn't match any notification code: $code");
    }
  }
}
