import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/models/checkout/error_response.dart';
import 'package:rentool/services/checkout_services.dart';
import 'package:rentool/services/functions.dart';

class CardInputScreen extends StatefulWidget {
  const CardInputScreen({Key? key}) : super(key: key);

  @override
  _CardInputScreenState createState() => _CardInputScreenState();
}

class _CardInputScreenState extends State<CardInputScreen> {
  CreditCardModel? card;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.enter_card)),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Hero(
                tag: 'CardWidget',
                child: Directionality(
                textDirection: TextDirection.ltr,
                child: CreditCardWidget(
                  customCardTypeIcons: [
                    CustomCardTypeIcon(
                      cardType: CardType.visa,
                      cardImage: Image.asset(
                        'assets/images/Visa_Brandmark_White_2021.png',
                        height: 48,
                        width: 48,
                      ),
                    ),
                  ],
                  cardNumber: card?.cardNumber ?? '',
                  expiryDate: card?.expiryDate ?? '',
                  cardHolderName: card?.cardHolderName ?? '',
                  cvvCode: card?.cvvCode ?? '',
                  showBackView: card?.isCvvFocused ?? false,
                  onCreditCardWidgetChange: (_) {},
                  isHolderNameVisible: true,
                ),
              ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: CreditCardForm(
                  cardNumber: card?.cardNumber ?? '',
                  expiryDate: card?.expiryDate ?? '',
                  cardHolderName: card?.cardHolderName ?? '',
                  cvvCode: card?.cvvCode ?? '',
                  onCreditCardModelChange: (newCard) {
                    setState(() {
                      card = newCard;
                    });
                  },
                  themeColor: Colors.blue,
                  formKey: formKey,
                  cardNumberDecoration: _fieldDecoration(context, AppLocalizations.of(context)!.card_number),
                  expiryDateDecoration: _fieldDecoration(context, AppLocalizations.of(context)!.expiry_date),
                  cardHolderDecoration: _fieldDecoration(context, AppLocalizations.of(context)!.card_holder_name),
                  cvvCodeDecoration: _fieldDecoration(context, AppLocalizations.of(context)!.ccv),
                  cvvValidationMessage: AppLocalizations.of(context)!.cvv_validation_message,
                  dateValidationMessage: AppLocalizations.of(context)!.date_validation_message,
                  numberValidationMessage: AppLocalizations.of(context)!.number_validation_message,
                ),
              ),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.submit.toUpperCase()),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    print('Valid!');
                    final number = card!.cardNumber.replaceAll(' ', '');
                    final expMonth = int.parse(card!.expiryDate.split('/')[0]);
                    final expYear = int.parse(card!.expiryDate.split('/')[1]) + 2000;

                    // Show loading indicator
                    showDialog(
                        context: context, builder: (context) => const Center(child: CircularProgressIndicator()));

                    try {
                      // Get token
                      final token = await CheckoutServices.genCardToken(
                        number,
                        expMonth,
                        expYear,
                        card!.cardHolderName,
                        card!.cvvCode,
                        null,
                      );

                      // Call servers to check card and create a customer.
                      final response = await FunctionsServices.addSourceFromToken(token.toJson(), token.headers);

                      // Pop loading indicator
                      Navigator.pop(context);

                      // throws [response] if [!response.isSuccess]
                      handleFunctionResponse(response);
                    } on FunctionResponse catch (response) {
                      return handleUnsuccessfulFunctionResponse(response);
                    } on ErrorResponse catch (_) {
                      return showIconErrorDialog(context, AppLocalizations.of(context)!.card_verification_invalid_data);
                    } on http.Response catch (e) {
                      print("Error (${e.statusCode}) setting user's card!");
                      print('-----Body-----');
                      print(e.body);
                      print('-----Headers-----');
                      print(e.headers);
                      return showIconErrorDialog(
                        context,
                        AppLocalizations.of(context)!.errorInfo + ':\nCode: ${e.statusCode}',
                      );
                    } catch (e) {
                      print(e);
                      return showIconErrorDialog(context, AppLocalizations.of(context)!.unexpected_error_occured);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// throws [result] if [!result.isSuccess]
  /// otherwise pop screen and show dialog of success
  void handleFunctionResponse(FunctionResponse result) {
    // if it wasn't successful throw it and it'll be caught by try-catch
    if (!result.isSuccess) throw result;

    // Pop the screen
    Navigator.pop(context);

    // Pending
    if (result.statusCode == 202) {
      showIconAlertDialog(
        context,
        icon: Icons.credit_card,
        titleText: AppLocalizations.of(context)!.pending,
        bodyText: AppLocalizations.of(context)!.request_success_but_pending,
      );
    } else if (result.statusCode == 201) {
      showIconAlertDialog(
        context,
        icon: Icons.credit_score,
        titleText: AppLocalizations.of(context)!.success,
        bodyText: AppLocalizations.of(context)!.request_success__status(result.message ?? '✔'),
      );
    }
  }

  handleUnsuccessfulFunctionResponse(FunctionResponse result) {
    if (result.error is! Map) {
      Navigator.pop(context);
      return showIconErrorDialog(
        context,
        AppLocalizations.of(context)!.errorInfo + '\n: Code:${result.statusCode}',
      );
    }
    switch (result.statusCode) {
      // Error codes:
      // unauthorized: not-signed-in
      // unauthorized: unverified-email-address
      case 401:
        Navigator.pop(context);
        switch ((result.error as Map)['code']) {
          case 'unverified-email-address':
            return showIconErrorDialog(
              context,
              AppLocalizations.of(context)!.email_address_not_verified,
              icon: Icons.no_accounts,
            );
          case 'not-signed-in':
            return showIconErrorDialog(
              context,
              AppLocalizations.of(context)!.card_verification_not_siged_in_error,
              icon: Icons.no_accounts,
            );
        }
        break;

      // Error codes:
      // unauthorized: no-email-registered
      case 403:
        Navigator.pop(context);
        return showIconErrorDialog(
          context,
          AppLocalizations.of(context)!.no_email_address,
          icon: Icons.alternate_email_rounded,
        );

      // Error codes:
      // bad-request: no-token-provided
      // bad-request: invalid-data
      case 400:
        switch ((result.error as Map)['code']) {
          case 'no-token-provided':
          case 'invalid-data':
            return showIconErrorDialog(context, AppLocalizations.of(context)!.card_verification_invalid_data);
        }
        break;

      // Error codes:
      // declined: declined
      case 406:
        return showIconErrorDialog(context, AppLocalizations.of(context)!.card_declined + '.');

      // Error codes:
      // too-many-requests: too-many-requests
      case 429:
        Navigator.pop(context);
        showIconErrorDialog(
          context,
          AppLocalizations.of(context)!.too_many_requests,
          icon: Icons.dangerous_outlined,
        );
        break;

      // Error codes:
      // bad-gateway: bad-gateway
      case 502:
        Navigator.pop(context);
        showIconErrorDialog(
          context,
          '${AppLocalizations.of(context)!.problem_on_our_side}.\n${AppLocalizations.of(context)!.bad_gateway}',
          icon: Icons.dns_outlined,
        );
        break;

      // Error codes:
      // internal-server-error: internal-server-error
      case 500:
        Navigator.pop(context);
        showIconErrorDialog(
          context,
          '${AppLocalizations.of(context)!.problem_on_our_side}.\n${AppLocalizations.of(context)!.internal_server_error}',
          icon: Icons.dns_outlined,
        );
        break;
    }
  }

  Future<dynamic> showIconErrorDialog(BuildContext context, String bodyText, {List<Widget>? actions, IconData? icon}) {
    return showIconAlertDialog(
      context,
      icon: icon ?? Icons.credit_card_off_outlined,
      titleText: AppLocalizations.of(context)!.error,
      bodyText: bodyText,
      actions: actions,
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppLocalizations.of(context)!.localeName == 'ar'
          ? const TextStyle(
              fontFamily: 'Almarai',
            )
          : null,
      errorStyle: AppLocalizations.of(context)!.localeName == 'ar'
          ? const TextStyle(
              fontFamily: 'Almarai',
            )
          : null,
    );
  }
}
