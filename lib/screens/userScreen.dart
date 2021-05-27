import 'package:flutter/material.dart';
import 'package:rentool/services/auth.dart';

class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user screen: ${AuthServices.auth.currentUser.displayName}'),
      ),
      body: ListView(
        children: [
          ListTile(
            trailing: OutlinedButton(
              child: Text('create post'),
              onPressed: () {
                //
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
        ],
      ),
    );
  }
}
