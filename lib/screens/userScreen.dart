import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/screens/NewPostScreen.dart';
import 'package:rentool/screens/SearchScreen.dart';
import 'package:rentool/services/auth.dart';

class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Screen'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Name:'),
            trailing: Text(
              AuthServices.auth.currentUser.displayName ?? '[NONE]',
              style: TextStyle(
                color: AuthServices.auth.currentUser.displayName == null ? Colors.red : null,
              ),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).emailAddress),
            trailing: Text(AuthServices.auth.currentUser.email),
          ),
          ListTile(
            title: Text('uid'),
            trailing: Text(AuthServices.auth.currentUser.uid),
          ),
          Divider(),
          ListTile(
            trailing: OutlinedButton(
              child: Text('SEARCH'),
              onPressed: () {
                //
                Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
              },
            ),
          ),
          ListTile(
            trailing: OutlinedButton(
              child: Text('CREATE POST'),
              onPressed: () {
                //
                Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostScreen()));
              },
            ),
          ),
          ListTile(
            title: Text(23141231231.toString()),
            trailing: OutlinedButton(
              child: Text('change ID number'),
              onPressed: () {
                //
              },
            ),
          ),
          ListTile(
            title: Text('xxxx xxxx xxxx 2293'),
            trailing: OutlinedButton(
              child: Text('add credit card'),
              onPressed: () {
                //
              },
            ),
          ),
          ListTile(
            title: ElevatedButton(
              child: Text('Sign out'),
              onPressed: () {
                AuthServices.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
