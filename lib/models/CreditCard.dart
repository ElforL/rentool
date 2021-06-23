class CreditCard {
  final String number;
  final String nameOnCard;
  final int expMonth;
  final int expYear;
  final String cvc;

  CreditCard(this.number, this.nameOnCard, this.expMonth, this.expYear, this.cvc) {
    if (number.length != 16) throw ArgumentError('Card number must be 16 digits: $number');
    if (cvc.length != 3) throw ArgumentError('CVC must be 3 digits: $cvc');
    if (expMonth < 1 && expMonth > 12) throw ArgumentError('Month must be from 1 to 12: $expMonth');

    var expiryDate = DateTime(expYear, expMonth);
    var today = DateTime.now();
    if (expiryDate.isBefore(today)) throw ArgumentError('Card is expired: $expMonth/$expYear');
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(json['number'], json['nameOnCard'], json['expMonth'], json['expYear'], json['cvc']);
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'nameOnCard': nameOnCard,
      'expMonth': expMonth,
      'expYear': expYear,
      'cvc': cvc,
    };
  }
}
