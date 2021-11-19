// couldn't fix it
// ignore_for_file: file_names

class Tool {
  final String id;
  final String ownerUID;
  String name;
  String description;
  double rentPrice;
  double insuranceAmount;
  List<String> media;
  String location;
  bool isAvailable;
  String? acceptedRequestID;
  String? currentRent;

  Tool(
    this.id,
    this.ownerUID,
    this.name,
    this.description,
    this.rentPrice,
    this.insuranceAmount,
    this.media,
    this.location,
    this.isAvailable, {
    this.acceptedRequestID,
    this.currentRent,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    var rent = json['rentPrice'];
    if (rent is! double) {
      if (rent is int) rent = rent.toDouble();
      if (rent is String) rent = double.parse(rent);
    }
    var insurance = json['insuranceAmount'];
    if (insurance is! double) {
      if (insurance is int) insurance = insurance.toDouble();
      if (insurance is String) insurance = double.parse(insurance);
    }

    return Tool(
      json['id'],
      json['ownerUID'],
      json['name'],
      json['description'],
      rent,
      insurance,
      json['media'] == null ? [] : List<String>.from(json['media']),
      json['location'],
      json['isAvailable'],
      acceptedRequestID: json['acceptedRequestID'],
      currentRent: json['currentRent'],
    );
  }

  Map<String, dynamic> toJson([List<String>? removedKeys]) {
    return {
      'id': id,
      'ownerUID': ownerUID,
      'name': name,
      'description': description,
      'rentPrice': rentPrice,
      'insuranceAmount': insuranceAmount,
      'media': media,
      'location': location,
      'isAvailable': isAvailable,
      'acceptedRequestID': acceptedRequestID,
      'currentRent': currentRent,
    }..removeWhere((key, value) => removedKeys?.contains(key) ?? false);
  }
}
