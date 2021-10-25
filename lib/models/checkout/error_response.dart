class ErrorResponse {
  final String requestId;
  final String errorType;
  final List<String> errorCodes;

  ErrorResponse(this.requestId, this.errorType, this.errorCodes);

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      json['request_id'],
      json['error_type'],
      List.from(json['error_codes']),
    );
  }
}
