class ToolRequest {
  final String id;
  final String renterUID;
  final String toolID;
  String description;
  int numOfDays;
  double rentPrice;
  double insuranceAmount;
  bool isAccepted;
  bool isRented;

  ToolRequest(
    this.id,
    this.renterUID,
    this.toolID,
    this.description,
    this.numOfDays,
    this.rentPrice,
    this.insuranceAmount,
    this.isAccepted,
    this.isRented,
  ) {
    if (numOfDays <= 0) {
      throw ArgumentError('numOfDays must be greater than 0. Received $numOfDays');
    }
    // renterUID =/= tool.ownerUID
  }

  factory ToolRequest.fromJson(Map<String, dynamic> json) {
    return ToolRequest(
      json['id'],
      json['renterUID'],
      json['toolID'],
      json['description'],
      json['numOfDays'],
      json['rentPrice'].toDouble(),
      json['insuranceAmount'].toDouble(),
      json['isAccepted'],
      json['isRented'],
    );
  }

  Map<String, dynamic> toJson([List<String>? removedKeys]) {
    return {
      'id': id,
      'renterUID': renterUID,
      'toolID': toolID,
      'description': description,
      'numOfDays': numOfDays,
      'rentPrice': rentPrice,
      'insuranceAmount': insuranceAmount,
      'isAccepted': isAccepted,
      'isRented': isRented,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
