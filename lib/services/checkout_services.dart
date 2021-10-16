import 'dart:convert';

import 'package:rentool/misc/constants.dart';
import 'package:http/http.dart' as http;
import 'package:rentool/models/checkout/error_response.dart';
import 'package:rentool/models/checkout/token_response.dart';

class CheckoutServices {
  /// [Request a token](https://api-reference.checkout.com/#operation/requestAToken)
  static const tokensUrl = 'https://api.sandbox.checkout.com/tokens';
  static get _headers => {'authorization': checkoutPublicKey};

  ///
  ///
  /// may throw [ErrorResponse] for error code 422
  /// or [Response] for errpr 404 and other
  static Future<CardToken> genCardToken(
    String number,
    int expMonth,
    int expYear,
    String name,
    String ccv,
    String? country,
  ) async {
    assert(expMonth >= 1 && expMonth <= 12, 'Invalid expiry month: $expMonth');
    assert(expYear % 1000 > 0, 'Expiry year must be 4 characters: $expYear');
    assert(DateTime.now().isBefore(DateTime(expYear, expMonth)), 'Expired card: $expMonth/$expYear');
    if (country != null) {
      assert(
        country.length == 2,
        'country must be the two-letter ISO country code of the address: $country\nCountry codes:https://docs.checkout.com/resources/codes/country-codes',
      );
    }

    final body = jsonEncode({
      'type': 'card',
      'number': number,
      'expiry_month': expMonth,
      'expiry_year': expYear,
      'name': name,
      'cvv': ccv,
      if (country != null)
        'billing_address': {
          'country': country,
        },
    });

    final response = await http.post(
      Uri.parse(tokensUrl),
      headers: _headers..addAll({'Content-Type': 'application/json'}),
      body: body,
    );

    if (response.statusCode == 201) {
      var json = jsonDecode(response.body);
      /*
      * TODO Call ckoPay for creating customer or adding a new card OUTSIDE AND AFTER THIS METHOD
      * THIS METHOD IS ONLY TO GENERATE THE TOKEN CALL THE `ckoPay()` AFTER CALLING THIS FUNCTION
      * DO CHECK Checkout docs to know when to call /payments with amound = 0
      * Also, TODO RENAME ckoPay
      */
      // final callable = FirebaseFunctions.instance.httpsCallable('ckoPay');
      // final msg = {
      //   'headers': response.headers..removeWhere((key, value) => !key.startsWith('cko')),
      //   'body': json,
      // };
      // await callable.call(msg);
      return CardToken.fromJson(json);
    } else {
      // An error occured
      if (response.statusCode == 422) {
        throw ErrorResponse.fromJson(jsonDecode(response.body));
      } else {
        throw response;
      }
    }
  }
}
