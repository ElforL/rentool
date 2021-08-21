import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/main.dart';
import 'package:rentool/screens/new_post_screen.dart';
import 'package:rentool/screens/search_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String? idNum;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final currentLocale = Locale(AppLocalizations.of(context)!.localeName);
              final currentIndex = AppLocalizations.supportedLocales.indexOf(currentLocale);
              final nextLocaleIndex = (currentIndex + 1) % AppLocalizations.supportedLocales.length;
              MyApp.of(context)!.setLocale(
                AppLocalizations.supportedLocales.elementAt(nextLocaleIndex),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Name:'),
            trailing: Text(
              AuthServices.auth.currentUser!.displayName ?? '[NONE]',
              style: TextStyle(
                color: AuthServices.auth.currentUser!.displayName == null ? Colors.red : null,
              ),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.emailAddress),
            trailing: Text(AuthServices.auth.currentUser!.email!),
          ),
          ListTile(
            title: const Text('uid'),
            trailing: Text(AuthServices.auth.currentUser!.uid),
          ),
          ListTile(
            title: const Text('verified'),
            trailing: Text(AuthServices.auth.currentUser!.emailVerified.toString()),
          ),
          const Divider(),
          ListTile(
            trailing: OutlinedButton(
              child: const Text('SEARCH'),
              onPressed: () {
                //
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
            ),
          ),
          ListTile(
            trailing: OutlinedButton(
              child: const Text('CREATE POST'),
              onPressed: () {
                Navigator.pushNamed(context, '/newPost');
              },
            ),
          ),
          // ID NUMBER
          FutureBuilder(
              future: FirestoreServices.getID(AuthServices.auth.currentUser!.uid),
              builder: (context, AsyncSnapshot<DocumentSnapshot<Object>> snapshot) {
                bool isDone = snapshot.connectionState == ConnectionState.done;
                if (isDone) {
                  if (snapshot.data != null && snapshot.data!.exists) idNum = snapshot.data!['idNumber'];
                }
                return ListTile(
                  title: Text(idNum ?? (isDone ? 'NOT CONFIGURED' : 'Loading...')),
                  trailing: OutlinedButton(
                    child: const Text('change ID number'),
                    onPressed: !isDone
                        ? null
                        : () async {
                            // Show dialog
                            var newID = await _showChangeIdDialog();
                            if (newID != null) {
                              print('newID = $newID');
                              FirestoreServices.updateID(AuthServices.auth.currentUser!.uid, newID);
                              setState(() {});
                            }
                          },
                  ),
                );
              }),
          ListTile(
            title: ElevatedButton(
              child: const Text('Sign out'),
              onPressed: () {
                AuthServices.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future _showChangeIdDialog() async {
    var _idController = TextEditingController();
    var dialog = AlertDialog(
      title: const Text('Change your ID number'),
      content: TextField(
        controller: _idController,
        decoration: const InputDecoration(hintText: 'Enter a new ID number'),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _idController.text);
          },
          child: const Text('CHANGE'),
        ),
      ],
    );
    return showDialog(context: context, builder: (_) => dialog);
  }
}
