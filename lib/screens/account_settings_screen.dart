import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/rentool/rentool_models.dart';
import 'package:rentool/screens/payment_settings_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/functions.dart';
import 'package:rentool/services/storage_services.dart';
import 'package:rentool/widgets/duration_disabled_button.dart';
import 'package:rentool/widgets/list_label.dart';
import 'package:rentool/widgets/loading_indicator.dart';
import 'package:rentool/widgets/rentool_circle_avatar.dart';
import 'package:rentool/widgets/set_id_dialog.dart';
import 'package:rentool/widgets/text_edit_list_tile.dart';

class AccountSettingsScreen extends StatefulWidget {
  AccountSettingsScreen({Key? key})
      : assert(AuthServices.currentUser != null),
        super(key: key);

  static const routeName = '/account_settings';

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  /// was [ModalRoute.of(context).settings.arguments] read?
  bool argumentsRead = false;
  RentoolUser? user;

  Future<void> _getUser() async {
    user ??= await FirestoreServices.getUser(AuthServices.currentUid!);
  }

  @override
  void initState() {
    if (!AuthServices.currentUser!.emailVerified) {
      AuthServices.currentUser!.reload();
    }
    super.initState();
  }

  Future<void> _uploadPhoto() async {
    ImagePicker picker = ImagePicker();
    XFile? xfile;
    xfile = await picker.pickImage(source: ImageSource.gallery);

    if (xfile != null) {
      final file = File(xfile.path);
      final task = await StorageServices.uploadUserPhoto(file, AuthServices.currentUid!);
      final photoUrl = await task.ref.getDownloadURL();
      await FunctionsServices.updateUserPhoto(photoUrl);
      setState(() => user!.photoURL = photoUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!argumentsRead) {
      argumentsRead = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is AccountSettingsScreenArguments) {
        user = args.user;
      }
    }
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, user);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.account_settings),
        ),
        body: FutureBuilder(
          future: _getUser(),
          builder: (context, snapshot) {
            if (user == null) {
              return const Center(
                child: LoadingIndicator(),
              );
            }
            return ListView(
              children: [
                ..._buildAppearance(),
                ..._buildAuthSection(),
                ..._buildIdSection(),
                ..._buildPaymentSection(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Contains the user photo and username
  List<Widget> _buildAppearance() {
    return [
      Center(
        child: RentoolCircleAvatar(
          user: user,
          radius: 60,
        ),
      ),
      Center(
        child: TextButton(
          child: Text(AppLocalizations.of(context)!.change_your_photo),
          onPressed: () => _uploadPhoto(),
        ),
      ),
      ListLabel(
        text: AppLocalizations.of(context)!.username,
        color: Colors.black54,
        hasLeadingSpace: false,
      ),
      TextEditListTile(
        defaultValue: user!.name,
        title: Text(user!.name),
        onSet: (newName) async {
          await FunctionsServices.updateUsername(newName);
          setState(() {
            user!.name = newName;
          });
        },
      ),
      const Divider(),
    ];
  }

  /// Contains the email address, send email verification, and resetting the password
  List<Widget> _buildAuthSection() {
    return [
      ListLabel(
        text: AppLocalizations.of(context)!.emailAddress,
        color: Colors.black54,
        hasLeadingSpace: false,
      ),
      ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(AuthServices.currentUser!.email ?? AppLocalizations.of(context)!.no_email_address),
        subtitle: AuthServices.currentUser!.emailVerified
            ? null
            : Text(
                '⚠ ' + AppLocalizations.of(context)!.email_address_not_verified,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      if (!AuthServices.currentUser!.emailVerified)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: AlignmentDirectional.topStart,
          child: TextButton(
            child: Text(AppLocalizations.of(context)!.resend_verification_email),
            onPressed: () {
              showIconAlertDialog(
                context,
                icon: Icons.mark_email_read_rounded,
                titleText: AppLocalizations.of(context)!.resend_verification_email,
                bodyText: AppLocalizations.of(context)!.check_inbox_for_verification_email,
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                    onPressed: () => Navigator.pop(context),
                  ),
                  DurationDisabledButton(
                    child: Text(AppLocalizations.of(context)!.resend_email.toUpperCase()),
                    onPressed: () => AuthServices.currentUser?.sendEmailVerification(),
                    seconds: 7,
                  ),
                ],
              );
            },
          ),
        ),
      if (AuthServices.currentUser!.email != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: AlignmentDirectional.topStart,
          child: TextButton(
            child: Text(AppLocalizations.of(context)!.change_your_password),
            onPressed: () async {
              final isSure = await showConfirmDialog(
                context,
                title: Text(AppLocalizations.of(context)!.areYouSure),
                content: Text(AppLocalizations.of(context)!.we_will_send_password_reset_email),
                actions: [
                  TextButton(
                    child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  DurationDisabledButton(
                    child: Text(AppLocalizations.of(context)!.sure.toUpperCase()),
                    onPressed: () => Navigator.pop(context, true),
                    seconds: 3,
                  ),
                ],
              );
              if (isSure != true) return;
              AuthServices.auth.sendPasswordResetEmail(email: AuthServices.currentUser!.email!);
              showIconAlertDialog(
                context,
                icon: Icons.password,
                titleText: AppLocalizations.of(context)!.reset_email_sent,
                bodyText: AppLocalizations.of(context)!.we_sent_password_reset_email,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  )
                ],
              );
            },
          ),
        ),
      const Divider(),
    ];
  }

  List<Widget> _buildIdSection() {
    return [
      ListLabel(
        text: AppLocalizations.of(context)!.id_number,
        color: Colors.black54,
        hasLeadingSpace: false,
      ),
      ListTile(
        title: Text(FirestoreServices.userIdNumber ?? AppLocalizations.of(context)!.no_id_number),
        subtitle: FirestoreServices.userIdNumber == null
            ? OutlinedButton(
                child: Text(AppLocalizations.of(context)!.set_id_number.toUpperCase()),
                onPressed: () async {
                  final result = await showDialog(context: context, builder: (_) => const SetIdDialog());
                  if (result != null && result is String) {
                    await FirestoreServices.setID(result);
                    setState(() {});
                  }
                },
              )
            : null,
      ),
      const Divider(),
    ];
  }

  List<Widget> _buildPaymentSection() {
    return [
      ListLabel(
        text: AppLocalizations.of(context)!.payment,
        color: Colors.black54,
        hasLeadingSpace: false,
      ),
      ListTile(
        title: Text(AppLocalizations.of(context)!.payment_settings),
        onTap: () {
          Navigator.of(context).pushNamed(PaymentSettingsScreen.routeName);
        },
      ),
      const Divider(),
    ];
  }
}

class AccountSettingsScreenArguments {
  final RentoolUser? user;

  AccountSettingsScreenArguments({
    this.user,
  }) : assert(
          user?.uid == AuthServices.currentUid,
          'user pushed for AccountSettingsScreen must be the currently signed in user',
        );
}
