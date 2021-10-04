import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rentool/services/firestore.dart';

class AuthServices {
  static FirebaseAuth auth = FirebaseAuth.instance;

  /// Returns `true` if the user is signed in and vice versa.
  static bool get isSignedIn => auth.currentUser != null;

  /// Returns the current [User] if they are currently signed-in, or null if not.
  static User? get currentUser => auth.currentUser;

  /// Returns the current [User] if they are currently signed-in, or `null` if not.
  static String? get currentUid => auth.currentUser?.uid;

  /// Notifies about changes to the user's sign-in state (such as sign-in or sign-out).
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Sign the user out
  static void signOut([String? uuid]) async {
    if (!isSignedIn) return;

    await FirebaseMessaging.instance.deleteToken();

    // get the device uuid to be able to navigate to the device's Firestore document and deleting the token
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? uuid;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await deviceInfo.androidInfo;
        uuid = androidInfo.androidId;
        break;
      case TargetPlatform.iOS:
        final iosInfo = await deviceInfo.iosInfo;
        uuid = iosInfo.identifierForVendor;
        break;
      default:
        return;
    }
    if (uuid != null) FirestoreServices.deleteDeviceToken(uuid, currentUid!);

    /// a list of the user information for each authentication provider.
    var providerData = auth.currentUser!.providerData;

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

  /// Tries to create a new user account with the given email address and
  /// password and send a verification email.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **email-already-in-use**:
  ///  - Thrown if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  static Future<UserCredential> createUserWithEmailAndPassword(String inEmail, String inPassword) async {
    var creds = await auth.createUserWithEmailAndPassword(
      email: inEmail,
      password: inPassword,
    );
    if (creds.additionalUserInfo!.isNewUser) auth.currentUser!.sendEmailVerification();
    return creds;
  }

  /// Sign in a user with the given email address and password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  static Future<UserCredential> signInWithEmailAndPassword(String inEmail, String inPassword) async {
    return await auth.signInWithEmailAndPassword(
      email: inEmail,
      password: inPassword,
    );
  }

  // source: https://firebase.flutter.dev/docs/auth/usage#reauthenticating-a-user
  /// Re-authenticates the user
  ///
  /// Use before operations such as [User.updatePassword] that require tokens
  /// from recent sign-in attempts.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **user-mismatch**:
  ///  - Thrown if the credential given does not correspond to the user.
  /// - **user-not-found**:
  ///  - Thrown if the credential given does not correspond to any existing
  ///    user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **invalid-email**:
  ///  - Thrown if the email used in a [EmailAuthProvider.credential] is
  ///    invalid.
  /// - **wrong-password**:
  ///  - Thrown if the password used in a [EmailAuthProvider.credential] is not
  ///    correct or when the user associated with the email does not have a
  ///    password.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  static Future<UserCredential> reauthenticateEmailAndPassword(String email, String password) {
    // Create a credential
    final credential = EmailAuthProvider.credential(email: email, password: password);

    // Reauthenticate
    return FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
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

  /// Throws an `Exception` if sign in process was aborted
  static Future<UserCredential> signInWithGoogleNative() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) throw Exception('Sign in process was aborted');

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

  // // TODO make sure this is the correct way
  // // my main problem was getting the credintials
  // // TODO if this way is correct it probably won't work for web. check Google sing in methods
  // static Future<UserCredential> reauthenticateGoogle() async {
  //   // Create a credential
  //   // Trigger the authentication flow
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  //   if (googleUser == null) throw Exception('Sign in process was aborted');

  //   // Obtain the auth details from the request
  //   final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  //   // Create a new credential
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );

  //   // Reauthenticate
  //   return FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(credential);
  // }

  /* ------------------ for Facebook Sign in ------------------ */

  static Future<UserCredential> signInWithFacebook() async {
    UserCredential creds;
    if (kIsWeb) {
      creds = await signInWithFacebookWeb();
    } else {
      creds = await signInWithFacebookNative();
    }
    if (creds.additionalUserInfo!.isNewUser) auth.currentUser!.sendEmailVerification();
    return creds;
  }

  // The following two methods were imported from FlutterFire documentation
  // https://firebase.flutter.dev/docs/auth/social#facebook [accessed at 9th May 2021]

  static Future<UserCredential> signInWithFacebookNative() async {
    // Trigger the sign-in flow
    final result = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final facebookAuthCredential = FacebookAuthProvider.credential(result.accessToken!.token);

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
