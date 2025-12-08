import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new route
  Future<String?> addRoute(RouteModel route) async {
    try {
      await _firestore.collection('routes').doc(route.id).set(route.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Get all routes
  Stream<List<RouteModel>> getRoutes() {
    return _firestore.collection('routes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RouteModel.fromMap(doc.data()))
          .toList();
    });
  }
}
