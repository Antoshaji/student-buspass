class BusPassRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail; // Added email
  final String routeId;
  final String routeName;
  final String stopName;
  final double cost;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestDate;

  BusPassRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.routeId,
    required this.routeName,
    required this.stopName,
    required this.cost,
    this.status = 'pending',
    required this.requestDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'routeId': routeId,
      'routeName': routeName,
      'stopName': stopName,
      'cost': cost,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
    };
  }

  factory BusPassRequestModel.fromMap(Map<String, dynamic> map) {
    return BusPassRequestModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      stopName: map['stopName'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      requestDate: DateTime.parse(map['requestDate']),
    );
  }
}
