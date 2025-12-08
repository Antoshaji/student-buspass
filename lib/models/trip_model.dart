class TripModel {
  final String id;
  final String studentId;
  final String route;
  final String stop;
  final double cost;
  final double remainingBalance;
  final DateTime timestamp;
  final String tripType; // 'From College' or 'To College'

  TripModel({
    required this.id,
    required this.studentId,
    required this.route,
    required this.stop,
    required this.cost,
    required this.remainingBalance,
    required this.timestamp,
    required this.tripType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'route': route,
      'stop': stop,
      'cost': cost,
      'remainingBalance': remainingBalance,
      'timestamp': timestamp.toIso8601String(),
      'tripType': tripType,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      route: map['route'] ?? '',
      stop: map['stop'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      tripType: map['tripType'] ?? '',
    );
  }
}
