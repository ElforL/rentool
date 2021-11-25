import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rentool/main.dart' as app;
import 'package:rentool/screens/home_page.dart';
import 'package:rentool/screens/login_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/widgets/user_listtile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const myEmail = 'fooBar@test.com';
  const myName = 'FooBar';
  const myPassword = 'HardPass@20';
  const myId = '1122334455';

  group('Functional Requirements', () {
    setUp(() {
      app.main([const Locale('en')]);
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

      await tester.enterText(emailTf, myEmail);
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
        await tester.enterText(emailTf, myEmail);

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
        await tester.pumpAndSettle();

        final Finder drawerBtn = find.byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip);
        await tester.tap(drawerBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(UserListTile));
        await tester.pumpAndSettle();

        final Finder accountSettingsBtn = find.text(AppLocalizationsEn().account_settings.toUpperCase());
        await tester.tap(accountSettingsBtn);
        await tester.pumpAndSettle();

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
  });
}
