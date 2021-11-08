import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_model.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';
import 'package:flutter_credit_card/custom_card_type_icon.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rentool/misc/dialogs.dart';
import 'package:rentool/screens/card_input_screen.dart';
import 'package:rentool/services/auth.dart';
import 'package:rentool/services/firestore.dart';
import 'package:rentool/services/functions.dart';
import 'package:rentool/widgets/loading_indicator.dart';
import 'package:rentool/widgets/note_box.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({Key? key}) : super(key: key);

  static const routeName = '/paymentSettings';

  @override
  _PaymentSettingsScreenState createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  CreditCardModel? card;
  bool hasCard = false;
  bool payouts = false;
  bool loaded = false;

  Future<void> _loadCardDetails() async {
    if (loaded) return;
    var number = '';
    var expiryDate = '';
    var cardHolderName = '[NO CARD]';

    // Get card
    final doc = await FirestoreServices.getCard(AuthServices.currentUid!);
    if (doc.exists && doc.data() != null && doc.data()!.isNotEmpty) {
      cardHolderName = doc.data()!['name'];

      final bin = doc.data()!['bin'].toString();
      final last4 = doc.data()!['last4'].toString();
      expiryDate = '${doc.data()!['expiry_month']}/${doc.data()!['expiry_year'].toString().substring(2)}';

      // the number is a string that starts with [bin] and ends with [last4]
      // in between them are number of zeros enough to make the card number length = 16
      // number of zeros = 16 - (bin.length + 4)
      // Then add a space after each 4 digits. and trim the final string to remove end space.
      number = '$bin${'0' * (16 - (bin.length + 4))}$last4'
          .replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ")
          .trim();

      payouts = doc.data()!['payouts'];
      FirestoreServices.hasCard = true;
      hasCard = true;
    }

    FirestoreServices.hasCard = false;
    card = CreditCardModel(number, expiryDate, cardHolderName, '', false);

    loaded = true;
  }

  _reload() {
    setState(() {
      hasCard = false;
      loaded = false;
      card = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.payment_settings),
      ),
      body: FutureBuilder(
          future: _loadCardDetails(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrintStack(label: snapshot.error.toString(), stackTrace: snapshot.stackTrace);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error,
                      size: 100,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppLocalizations.of(context)!.unexpected_error_occured,
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!loaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoadingIndicator(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppLocalizations.of(context)!.loading_payment_settings,
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _reload();
              },
              child: ListView(
                children: [
                  _buildCardWidget(),
                  if (hasCard && !payouts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: NoteBox(
                          mainColor: Colors.red,
                          text: /* hasCard && !payouts ? */ AppLocalizations.of(context)!.no_payouts,
                          icon: Icons.warning,
                        ),
                      ),
                    ),
                  buildButtons(),
                ],
              ),
            );
          }),
    );
  }

  Widget buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          if (hasCard) ...[
            SizedBox(
              width: 100,
              child: OutlinedButton(
                child: Text(AppLocalizations.of(context)!.delete.toUpperCase()),
                onPressed: () async {
                  final isSure = await showDeleteConfirmDialog(context);
                  if (isSure ?? false) {
                    showCircularLoadingIndicator(context);
                    final result = await FunctionsServices.deleteCard();
                    // Pop the loading indicator
                    Navigator.pop(context);

                    if (result.isSuccess) {
                      setState(() {
                        hasCard = false;
                        card = CreditCardModel('', '', '', '', false);
                      });
                    } else {
                      showErrorDialog(context);
                      debugPrint('${result.statusCode}: ${result.error}');
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 20),
          ],
          SizedBox(
            width: 200,
            child: OutlinedButton(
              child: Text(
                hasCard
                    ? AppLocalizations.of(context)!.change_your_card.toUpperCase()
                    : AppLocalizations.of(context)!.enter_card.toUpperCase(),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CardInputScreen()),
                );
                _reload();
              },
            ),
          ),
        ],
      ),
    );
  }

  Center _buildCardWidget() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Hero(
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
              isSwipeGestureEnabled: false,
              cardNumber: card!.cardNumber,
              expiryDate: card!.expiryDate,
              cardHolderName: card!.cardHolderName,
              cvvCode: '',
              isHolderNameVisible: true,
              showBackView: false,
              onCreditCardWidgetChange: (_) {},
              cardBgColor: Colors.blue.shade900,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> showDeleteConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context,
      content: Text(
        AppLocalizations.of(context)!.want_delete_your_card,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
        ),
        TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.red),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.of(context)!.delete.toUpperCase()),
        ),
      ],
    );
  }
}
