import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthServices {
  FirebaseAuth auth;

  AuthServices() : auth = FirebaseAuth.instance {
    auth.authStateChanges().listen((User user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  /* ------------------ for Google Sign in ------------------ */

  // The following methods was imported from Flutterfire documentaion
  // https://firebase.flutter.dev/docs/auth/social#google [accessed at 9th May 21]

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return await signInWithGoogleWeb();
    } else {
      return await signInWithGoogleNative();
    }
  }

  Future<UserCredential> signInWithGoogleWeb() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  Future<UserCredential> signInWithGoogleNative() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  // The following method was imported from Flutterfire documentaion
  // https://firebase.flutter.dev/docs/auth/social#facebook [accessed at 9th May 21]

  // TODO implement facebook sign-in

  /* ------------------ for Apple Sign in ------------------ */
  // The following three methods were imported from Flutterfire documentaion
  // https://firebase.flutter.dev/docs/auth/social#apple [accessed at 9th May 21]
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      return await signInWithAppleWeb();
    } else {
      return await signInWithAppleIOS();
    }
  }

  Future<UserCredential> signInWithAppleWeb() async {
    // Create and configure an OAuthProvider for Sign In with Apple.
    final provider = OAuthProvider("apple.com")..addScope('email')..addScope('name');

    // Sign in the user with Firebase.
    return await FirebaseAuth.instance.signInWithPopup(provider);
  }

  Future<UserCredential> signInWithAppleIOS() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    return await auth.signInWithCredential(oauthCredential);
  }

  String generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /* ------------------ End of Apple Sign in methods ------------------ */
}
