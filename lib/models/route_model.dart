class RouteModel {
  final String id;
  final String name;
  final List<StopModel> stops;

  RouteModel({required this.id, required this.name, required this.stops});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stops': stops.map((x) => x.toMap()).toList(),
    };
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      stops: List<StopModel>.from(
        (map['stops'] as List<dynamic>).map<StopModel>(
          (x) => StopModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RouteModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class StopModel {
  final String name;
  final int stopNumber;
  final double cost;

  StopModel({required this.name, required this.stopNumber, required this.cost});

  Map<String, dynamic> toMap() {
    return {'name': name, 'stopNumber': stopNumber, 'cost': cost};
  }

  factory StopModel.fromMap(Map<String, dynamic> map) {
    return StopModel(
      name: map['name'] ?? '',
      stopNumber: map['stopNumber']?.toInt() ?? 0,
      cost: (map['cost'] ?? 0.0).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StopModel &&
        other.name == name &&
        other.stopNumber == stopNumber &&
        other.cost == cost;
  }

  @override
  int get hashCode => name.hashCode ^ stopNumber.hashCode ^ cost.hashCode;
}
