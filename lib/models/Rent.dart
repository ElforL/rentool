class Rent {
  final String toolID;
  final String requestID;
  final DateTime startTime;
  DateTime? endTime;

  Rent(this.toolID, this.requestID, this.startTime, [this.endTime]) {
    if (endTime != null && endTime!.isBefore(startTime)) {
      throw ArgumentError('endTime must be after startTime');
    }
  }

  factory Rent.fromJson(Map<String, dynamic> json) {
    return Rent(
      json['toolID'],
      json['requestID'],
      json['startTime'],
      json['endTime'],
    );
  }
}
