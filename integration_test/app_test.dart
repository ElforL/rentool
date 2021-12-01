import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rentool/localization/cities_localization.dart';
import 'package:rentool/main.dart' as app;
import 'package:rentool/screens/card_input_screen.dart';
import 'package:rentool/screens/edit_post_screen.dart';
import 'package:rentool/screens/home_page.dart';
import 'package:rentool/screens/login_screen.dart';
import 'package:rentool/screens/post_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/tool_tile.dart';
import 'package:rentool/widgets/user_listtile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const newEmail = 'fooBar@test.com';
  const myName = 'FooBar';
  const myPassword = String.fromEnvironment('password');
  const myId = '1122334455';

  /// the email address of an email verified account
  const emailVerifiedEmail = String.fromEnvironment('emailVerifiedEmail');
  const adminEmailAddress = String.fromEnvironment('adminEmailAddress');
  const secondEmail = String.fromEnvironment('secondEmail');

  group('Functional Requirements', () {
    setUp(() {
      app.main();
    });

    testWidgets('FR2- The system must allow the user to create an account.', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget, reason: '"The Sign-up screen is displayed"');

      final Finder emailTf = find.byWidgetPredicate((widget) {
        return widget is TextField && (widget.autofillHints?.contains(AutofillHints.email) ?? false);
      });
      final Finder usernameTf = find.byWidgetPredicate((widget) {
        return widget is TextField && (widget.autofillHints?.contains(AutofillHints.username) ?? false);
      });
      final Finder passwordTf = find.byWidgetPredicate((widget) {
        return widget is TextField && (widget.decoration?.labelText == AppLocalizationsEn().password);
      });
      final Finder confirmPasswordTf = find.byWidgetPredicate((widget) {
        return widget is TextField && (widget.decoration?.labelText == AppLocalizationsEn().form_confirm_password);
      });

      expect(emailTf, findsOneWidget);

      await tester.enterText(emailTf, newEmail);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(4));

      await tester.enterText(usernameTf, myName);
      await tester.enterText(passwordTf, myPassword);
      await tester.enterText(confirmPasswordTf, myPassword);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets(
      'FR3- The system must allow the user to log-in/sign-up using a Google, Facebook, Microsoft',
      (WidgetTester tester) async {
        await AuthServices.signOut();
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget, reason: '"The Sign-up screen is displayed"');

        expect(find.text('SIGN IN WITH GOOGLE'), findsOneWidget);
        expect(find.text('Login with Facebook'), findsOneWidget);
        // IF YOU REMOVE MS BUTTON, DELETE MS NAME FROM THE TEST TITLE ABOVE
        expect(find.text('Sign in with Microsoft'), findsOneWidget);
      },
    );

    testWidgets(
      'FR5 & FR6\nThe system must allow the user to log into his/her account.\nThe system must be check if the log-in details are correct.',
      (WidgetTester tester) async {
        await AuthServices.signOut();
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget, reason: '"The Sign-up screen is displayed"');

        final Finder emailTf = find.byWidgetPredicate((widget) {
          return widget is TextField && (widget.autofillHints?.contains(AutofillHints.email) ?? false);
        });
        final Finder passwordTf = find.byWidgetPredicate((widget) {
          return widget is TextField && (widget.decoration?.labelText == AppLocalizationsEn().password);
        });

        expect(emailTf, findsOneWidget);
        await tester.enterText(emailTf, emailVerifiedEmail);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(2));

        await tester.enterText(passwordTf, myPassword);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    testWidgets(
      'FR4- The system must allow the user to enter his/her ID number.',
      (WidgetTester tester) async {
        await ensureUserSignedIn(emailVerifiedEmail, myPassword);

        await tester.pumpAndSettle();

        await gotoAccountSettings(tester);

        expect(find.text(AppLocalizationsEn().no_id_number), findsOneWidget);
        await tester.tap(find.text(AppLocalizationsEn().set_id_number.toUpperCase()));
        await tester.pumpAndSettle();

        final Finder idTf = find.byWidgetPredicate((widget) {
          return widget is TextField && (widget.keyboardType == TextInputType.number);
        });

        expect(idTf, findsOneWidget);

        await tester.enterText(idTf, myId);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.tap(find.text(AppLocalizationsEn().set.toUpperCase()));
        await tester.pumpAndSettle();

        // wait 1 second to ensure setId() was done
        await Future.delayed(const Duration(seconds: 1));

        final doc = await FirestoreServices.getID(AuthServices.currentUid!);
        final idTest = (doc.data() as Map)['idNumber'];
        expect(idTest, myId);
      },
    );
    testWidgets(
      'FR9 & FR10 Invalid card will be declined',
      (WidgetTester tester) async {
        await ensureUserSignedIn(emailVerifiedEmail, myPassword);
        await tester.pumpAndSettle();
        await gotoAccountSettings(tester);

        // Go to payment settings page
        await tester.tap(find.text(AppLocalizationsEn().payment_settings));
        await tester.pumpAndSettle();

        // Tap "Enter you card" button
        await tester.tap(find.text(AppLocalizationsEn().enter_card.toUpperCase()));
        await tester.pumpAndSettle();

        // should to be in the input form
        expect(find.byType(CardInputScreen), findsOneWidget);

        final cardNumberTf = find.byWidgetPredicate((widget) {
          return widget is TextField && widget.decoration?.labelText == AppLocalizationsEn().card_number;
        });

        // Card number
        expect(cardNumberTf, findsOneWidget);
        await tester.enterText(cardNumberTf, '4242424242424242');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // Expiry date
        tester.testTextInput.enterText('0133');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // CCV
        tester.testTextInput.enterText('120');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // Name
        tester.testTextInput.enterText('Foo Bar');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppLocalizationsEn().submit.toUpperCase()));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text(AppLocalizationsEn().card_declined + '.'), findsOneWidget);
      },
    );

    testWidgets(
      'FR9 & FR10 Valid card will be accepted',
      (WidgetTester tester) async {
        await ensureUserSignedIn(emailVerifiedEmail, myPassword);
        await tester.pumpAndSettle();
        await gotoAccountSettings(tester);

        // Go to payment settings page
        await tester.tap(find.text(AppLocalizationsEn().payment_settings));
        await tester.pumpAndSettle();

        // Tap "Enter you card" button
        await tester.tap(find.text(AppLocalizationsEn().enter_card.toUpperCase()));
        await tester.pumpAndSettle();

        // should to be in the input form
        expect(find.byType(CardInputScreen), findsOneWidget);

        final cardNumberTf = find.byWidgetPredicate((widget) {
          return widget is TextField && widget.decoration?.labelText == AppLocalizationsEn().card_number;
        });

        // Card number
        expect(cardNumberTf, findsOneWidget);
        await tester.enterText(cardNumberTf, '4242424242424242');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // Expiry date
        tester.testTextInput.enterText('0133');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // CCV
        tester.testTextInput.enterText('100');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        // Name
        tester.testTextInput.enterText('Foo Bar');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        await tester.tap(find.text(AppLocalizationsEn().submit.toUpperCase()));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text(AppLocalizationsEn().success), findsOneWidget);
      },
    );

    testWidgets('FR11 - The system must allow the user (owner) to create a new post', (WidgetTester tester) async {
      await ensureUserSignedIn(emailVerifiedEmail, myPassword);
      await tester.pumpAndSettle();

      // Open the drawer
      final Finder drawerBtn = find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip);
      await tester.tap(drawerBtn);
      await tester.pumpAndSettle();

      // press "my tools"
      await tester.tap(find.text(AppLocalizationsEn().myTools));
      await tester.pumpAndSettle();

      // Press the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(EditPostScreen), findsOneWidget);

      // Enter tool name
      final nameTf = find.byWidgetPredicate((widget) {
        return widget is TextField && widget.decoration?.labelText == AppLocalizationsEn().tool_name;
      });
      const toolName = 'New tool';
      await tester.enterText(nameTf, toolName);

      // Enter tool description
      await tester.testTextInput.receiveAction(TextInputAction.next);
      tester.testTextInput.enterText('Description of New tool');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Enter rent price
      final rentTf = find.byWidgetPredicate((widget) {
        return widget is TextField && widget.decoration?.labelText == AppLocalizationsEn().rentPrice;
      });
      await tester.enterText(rentTf, '5');

      // Enter insurance
      await tester.testTextInput.receiveAction(TextInputAction.next);
      tester.testTextInput.enterText('20');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Enter location
      await tester.tap(find.text(AppLocalizationsEn().choose_a_city));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CityLocalization.cityName('abha', 'en')).first);
      await tester.pumpAndSettle();

      // Press create
      final createBtn = find.text(AppLocalizationsEn().create);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // ignore: deprecated_member_use_from_same_package
      final query = await FirestoreServices.searchForTool(toolName);
      bool found = false;
      for (var doc in query) {
        var data = doc.data();
        if (data is Map && data['name'] == toolName) {
          found = true;
          break;
        }
      }

      expect(found, true);
    });

    testWidgets('FR13- The system must allow the owner to edit and delete their posts', (WidgetTester tester) async {
      await ensureUserSignedIn(emailVerifiedEmail, myPassword);
      await tester.pumpAndSettle();

      // Open the drawer
      final Finder drawerBtn = find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip);
      await tester.tap(drawerBtn);
      await tester.pumpAndSettle();

      // press "my tools"
      await tester.tap(find.text(AppLocalizationsEn().myTools));
      await tester.pumpAndSettle();

      // Press the first tool
      await tester.tap(find.byType(ToolTile));
      await tester.pumpAndSettle();

      expect(find.byType(PostScreen), findsOneWidget);

      // Press the "more" button
      await tester.tap(find.byTooltip(const DefaultMaterialLocalizations().moreButtonTooltip));
      await tester.pumpAndSettle();

      // Expect edit and delete buttons
      expect(find.text(AppLocalizationsEn().edit), findsOneWidget);
      expect(find.text(AppLocalizationsEn().delete), findsOneWidget);

      // Press "Edit"
      await tester.tap(find.text(AppLocalizationsEn().edit));
      await tester.pumpAndSettle();

      expect(find.byType(EditPostScreen), findsOneWidget);

      // Enter tool name
      final descriptionTf = find.byWidgetPredicate((widget) {
        return widget is TextField && widget.decoration?.labelText == AppLocalizationsEn().description;
      });
      const newDescription = 'This is the new description';
      await tester.enterText(descriptionTf, newDescription);
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Press create
      final editBtn = find.text(AppLocalizationsEn().edit);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PostScreen), findsOneWidget);
      expect(find.text(newDescription), findsOneWidget);
    });
  });
}

/// returns immediately if `AuthServices.currentUser != null`
///
/// otherwise, it logs in the user with [myEmail] and [myPassword].
/// OR, creates a new user if it caught a [FirebaseException] during login.
Future<void> ensureUserSignedIn(String myEmail, String myPassword) async {
  if (AuthServices.currentUser != null) return;
  try {
    await AuthServices.signInWithEmailAndPassword(myEmail, myPassword);
  } on FirebaseException catch (_) {
    await AuthServices.createUserWithEmailAndPassword(myEmail, myPassword);
  }
}

/// Navigates to the account settings **from the home page**
///
/// Steps:
/// 1. press the 'open drawer' button on the AppBar
/// 2. press on the user tile
/// 3. press on the account settings button
Future<void> gotoAccountSettings(WidgetTester tester) async {
  final Finder drawerBtn = find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip);
  await tester.tap(drawerBtn);
  await tester.pumpAndSettle();

  await tester.tap(find.byType(UserListTile));
  await tester.pumpAndSettle();

  final Finder accountSettingsBtn = find.text(AppLocalizationsEn().account_settings.toUpperCase());
  await tester.tap(accountSettingsBtn);
  await tester.pumpAndSettle();
}
