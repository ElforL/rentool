class ToolRequest {
  final String id;
  final String renterUID;
  final String toolID;
  int numOfDays;
  double rentPrice;
  double insuranceAmount;
  bool isAccepted;
  bool isRented;

  ToolRequest(
    this.id,
    this.renterUID,
    this.toolID,
    this.numOfDays,
    this.rentPrice,
    this.insuranceAmount,
    this.isAccepted,
    this.isRented,
  ) {
    if (numOfDays <= 0) {
      throw ArgumentError('numOfDays must be greater than 0. Recived $numOfDays');
    }
    // renterUID =/= tool.ownerUID
  }

  factory ToolRequest.fromJson(Map<String, dynamic> json) {
    return ToolRequest(
      json['id'],
      json['renterUID'],
      json['toolID'],
      json['numOfDays'],
      json['rentPrice'],
      json['insuranceAmount'],
      json['isAccepted'],
      json['isRented'],
    );
  }
}
