import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/services/auth.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: user.photoURL == null
            ? Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Image.network(user.photoURL!),
        backgroundColor: user.photoURL == null ? Colors.black12 : Colors.transparent,
      ),
      title: Text(user.displayName ?? 'Account'),
      trailing: TextButton(
        child: Text(AppLocalizations.of(context)!.signOut),
        onPressed: () => AuthServices.signOut(),
      ),
    );
  }
}
