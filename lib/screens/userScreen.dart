import 'package:flutter/material.dart';
import 'package:rentool/screens/NewPostScreen.dart';
import 'package:rentool/screens/PostScreen.dart';
import 'package:rentool/services/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool_sdk/rentool_sdk.dart';

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
            title: Text('verified?'),
            trailing: Text(AuthServices.auth.currentUser.emailVerified.toString()),
          ),
          Divider(),
          ListTile(
            trailing: OutlinedButton(
              child: Text('create post'),
              onPressed: () {
                //
                Navigator.push(context, MaterialPageRoute(builder: (_) => NewPostScreen()));
              },
            ),
          ),
          ListTile(
            trailing: OutlinedButton(
              child: Text('view post'),
              onPressed: () {
                var tool = Tool(
                  '42069',
                  'xx420xx',
                  'Philips Blender 700 W, 1.5lt glass jar, 5 speeds with crush technology, HR2222/01',
                  '''5 pre-sets
Removable lid & knife
Crushed ice 2x faster
700W, 1.5 liter glass jar''',
                  23,
                  120,
                  [
                    'https://images-na.ssl-images-amazon.com/images/I/714G2dHmcaL._AC_SL1500_.jpg',
                    'https://images-na.ssl-images-amazon.com/images/I/71%2BRcdS6udL._AC_SL1500_.jpg',
                    'https://images-na.ssl-images-amazon.com/images/I/81J%2Btj9dlSL._AC_SL1500_.jpg',
                    'https://images-na.ssl-images-amazon.com/images/I/71Lyx3BixRL._AC_SL1301_.jpg',
                  ],
                  'Riyadh',
                  true,
                );
                Navigator.push(context, MaterialPageRoute(builder: (_) => PostScreen(tool: tool)));
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
