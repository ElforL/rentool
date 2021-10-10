import 'package:flutter/material.dart';

class ReauthenticateScreen extends StatefulWidget {
  const ReauthenticateScreen({Key? key}) : super(key: key);

  @override
  ReauthenticateScreenState createState() => ReauthenticateScreenState();
}

// how TODO it
// check each provider
// if 'password' exist then go for [AuthServices.reauthenticateEmailAndPassword(email, password)]
// THEN check for other providers and call their reauth function

class ReauthenticateScreenState extends State<ReauthenticateScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
