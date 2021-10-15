import 'package:rentool/models/checkout/general.dart';

class CardToken {
  final String type = 'card';
  final String token;
  final String expiresOn;
  final String last4;
  final String bin;
  final int expMonth;
  final int expYear;

  final String? scheme;
  final String? cardType;
  final String? cardCategory;
  final String? issuer;
  final String? issuerCountry;
  final String? productId;
  final String? productType;

  final BillingAddress? billingAddress;
  final PhoneNumber? phoneNumber;

  final String? name;

  CardToken(
    this.token,
    this.expiresOn,
    this.last4,
    this.bin,
    this.expMonth,
    this.expYear, {
    this.scheme,
    this.cardType,
    this.cardCategory,
    this.issuer,
    this.issuerCountry,
    this.productId,
    this.productType,
    this.billingAddress,
    this.phoneNumber,
    this.name,
  });

  factory CardToken.fromJson(Map<String, dynamic> json) {
    return CardToken(
      json['token'],
      json['expires_on'],
      json['last4'],
      json['bin'],
      json['expiry_month'],
      json['expiry_year'],
      scheme: json['scheme'],
      cardType: json['card_type'],
      cardCategory: json['card_category'],
      issuer: json['issuer'],
      issuerCountry: json['issuer_country'],
      productId: json['product_id'],
      productType: json['product_type'],
      billingAddress: json['billing_address'] != null ? BillingAddress.fromJson(json['billing_address']) : null,
      phoneNumber: json['phone'] != null ? PhoneNumber.fromJson(json['phone']) : null,
      name: json['name'],
    );
  }
}
