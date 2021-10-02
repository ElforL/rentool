import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/widgets/rentool_circle_avatar.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    Key? key,
    required this.user,
    this.onTap,
  }) : super(key: key);

  final User user;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: RentoolCircleAvatar.firebaseUser(
        user: user,
      ),
      onTap: onTap,
      title: Text(AppLocalizations.of(context)!.my_account),
      trailing: TextButton(
        child: Text(AppLocalizations.of(context)!.signOut.toUpperCase()),
        onPressed: () async {
          final isSure = await showConfirmDialog(context);
          if (isSure ?? false) AuthServices.signOut();
        },
      ),
    );
  }
}
