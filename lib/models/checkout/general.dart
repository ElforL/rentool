class PhoneNumber {
  /// The international [country calling code](https://docs.checkout.com/resources/codes/country-codes). Required for some risk checks.
  ///
  /// [ 1 .. 7 ] characters
  final String countryCode;

  /// The phone number.
  ///
  /// [ 6 .. 25 ] characters
  final String number;

  PhoneNumber(this.countryCode, this.number)
      : assert(
          number.length >= 6 && number.length <= 25,
          'Phone number must be between 6 to 25 characters. recived length: ${number.length}',
        ),
        assert(
          // ignore: prefer_is_empty
          countryCode.length >= 1 && countryCode.length <= 7,
          'Country code must be between 1 to 7 characters. recived length: ${countryCode.length}',
        );

  factory PhoneNumber.fromJson(Map<String, dynamic> json) {
    return PhoneNumber(
      json['country_code'],
      json['number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'number': number,
    };
  }
}

class BillingAddress {
  /// The first line of the address
  ///
  /// <= 200 characters
  final String addressLine1;

  /// The second line of the address
  ///
  /// <= 200 characters
  final String addressLine2;

  /// The address city
  ///
  /// <= 50 characters
  final String city;

  /// The address state
  ///
  /// <= 50 characters
  final String state;

  /// The address zip/postal code
  ///
  /// <= 50 characters
  final String zip;

  /// The two-letter [ISO country code](https://docs.checkout.com/resources/codes/country-codes) of the address
  ///
  /// 2 characters
  final String country;

  BillingAddress(this.addressLine1, this.addressLine2, this.city, this.state, this.zip, this.country);

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      json['address_line1'],
      json['address_line2'],
      json['city'],
      json['state'],
      json['zip'],
      json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };
  }
}
