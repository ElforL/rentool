import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/models/checkout/error_response.dart';
import 'package:rentool/services/checkout_services.dart';

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
              Directionality(
                textDirection: TextDirection.ltr,
                child: CreditCardWidget(
                  cardNumber: card?.cardNumber ?? '',
                  expiryDate: card?.expiryDate ?? '',
                  cardHolderName: card?.cardHolderName ?? '',
                  cvvCode: card?.cvvCode ?? '',
                  showBackView: card?.isCvvFocused ?? false,
                  onCreditCardWidgetChange: (_) {},
                  isHolderNameVisible: true,
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
                child: Text(AppLocalizations.of(context)!.enter_card),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    print('Valid!');
                    final number = card!.cardNumber.replaceAll(' ', '');
                    final expMonth = int.parse(card!.expiryDate.split('/')[0]);
                    final expYear = int.parse(card!.expiryDate.split('/')[1]) + 2000;
                    try {
                      final res = await CheckoutServices.genCardToken(
                        number,
                        expMonth,
                        expYear,
                        card!.cardHolderName,
                        card!.cvvCode,
                        null,
                      );
                      print('Done!');
                      print(res.name);
                      print(res.last4);
                      print(res.token);
                    } on ErrorResponse catch (e) {
                      print('Error 422!');
                      print(e.requestId);
                      print(e.errorType);
                      print(e.errorCodes);
                    }
                  } else {
                    print('invalid!');
                  }
                },
              ),
            ],
          ),
        ),
      ),
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
