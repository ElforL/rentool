import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  static FirebaseAuth auth = FirebaseAuth.instance;

  static bool get isSignedIn => auth.currentUser != null;

  static Stream<User> get authStateChanges => auth.authStateChanges();

  static void signOut() async {
    /// a list of the user information for each authentication provider.
    var providerData = auth.currentUser.providerData;

    /// checks if the user has an authintication provider with the given [providerId].
    bool _isProviderUsed(String providerId) {
      return providerData.any((provider) => provider.providerId == providerId);
    }

    await auth.signOut();
    try {
      if (_isProviderUsed('google.com')) {
        await GoogleSignIn().signOut();
        print('G logout');
      }
      if (_isProviderUsed('facebook.com')) {
        await FacebookAuth.instance.logOut();
        print('FB logout');
      }
    } catch (e) {
      print(e);
    }
  }

  /* ------------------ for Email Sign in ------------------ */

  static Future<UserCredential> createUserWithEmailAndPassword(String inEmail, String inPassword) async {
    var creds = await auth.createUserWithEmailAndPassword(
      email: inEmail,
      password: inPassword,
    );
    if (creds.additionalUserInfo.isNewUser) auth.currentUser.sendEmailVerification();
    return creds;
  }

  static Future<UserCredential> signInWithEmailAndPassword(String inEmail, String inPassword) async {
    return await auth.signInWithEmailAndPassword(
      email: inEmail,
      password: inPassword,
    );
  }

  /* ------------------ for Google Sign in ------------------ */

  static Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return await signInWithGoogleWeb();
    } else {
      return await signInWithGoogleNative();
    }
  }

  // The following two methods were imported from FlutterFire documentation
  // https://firebase.flutter.dev/docs/auth/social#google [accessed at 9th May 2021]

  static Future<UserCredential> signInWithGoogleWeb() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    // googleProvider.addScope('https://www.googleapis.com/auth/');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    // Once signed in, return the UserCredential
    return await auth.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await auth.signInWithRedirect(googleProvider);
  }

  static Future<UserCredential> signInWithGoogleNative() async {
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
    return await auth.signInWithCredential(credential);
  }

  /* ------------------ for Facebook Sign in ------------------ */

  static Future<UserCredential> signInWithFacebook() async {
    UserCredential creds;
    if (kIsWeb) {
      creds = await signInWithFacebookWeb();
    } else {
      creds = await signInWithFacebookNative();
    }
    if (creds.additionalUserInfo.isNewUser) auth.currentUser.sendEmailVerification();
    return creds;
  }

  // The following two methods were imported from FlutterFire documentation
  // https://firebase.flutter.dev/docs/auth/social#facebook [accessed at 9th May 2021]

  static Future<UserCredential> signInWithFacebookNative() async {
    // Trigger the sign-in flow
    final result = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final facebookAuthCredential = FacebookAuthProvider.credential(result.accessToken.token);

    // Once signed in, return the UserCredential
    return await auth.signInWithCredential(facebookAuthCredential);
  }

  static Future<UserCredential> signInWithFacebookWeb() async {
    // Create a new provider
    FacebookAuthProvider facebookProvider = FacebookAuthProvider();

    // facebookProvider.addScope('email');
    facebookProvider.setCustomParameters({
      'display': 'popup',
    });

    // Once signed in, return the UserCredential
    return await auth.signInWithPopup(facebookProvider);
  }

  /* ------------------ for Apple Sign in ------------------ */

  /* 
  static Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      return await signInWithAppleWeb();
    } else {
      return await signInWithAppleIOS();
    }
  }

  // The following four methods were imported from Flutterfire documentaion
  // https://firebase.flutter.dev/docs/auth/social#apple [accessed at 9th May 2021]

  static Future<UserCredential> signInWithAppleWeb() async {
    // Create and configure an OAuthProvider for Sign In with Apple.
    final provider = OAuthProvider("apple.com")..addScope('email')..addScope('name');

    // Sign in the user with Firebase.
    return await auth.signInWithPopup(provider);
  }

  static Future<UserCredential> signInWithAppleIOS() async {
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

  static String generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  */

  /* ------------------ End of Apple Sign in methods ------------------ */
}
