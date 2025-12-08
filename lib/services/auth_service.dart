import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes mapped to UserModel
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('Error fetching user details: $e');
      }
      return null;
    });
  }

  // Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? studentId,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          role: role,
          studentId: studentId,
        );
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap())
              .timeout(const Duration(seconds: 5)); // Add timeout
        } catch (e) {
          print('Firestore Error: $e');
          return 'Signup Successful but failed to save data: $e';
        }
        notifyListeners();
        return null; // Success
      }
      return 'User creation failed';
    } on FirebaseAuthException catch (e) {
      return 'Auth Error: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Login for Admin (Email + Password)
  Future<String?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Auth Error: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Login for Student (Student ID + Password)
  Future<String?> loginStudent({
    required String studentId,
    required String password,
  }) async {
    try {
      // 1. Find email associated with studentId
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        return 'Student ID not found';
      }

      final userDoc = result.docs.first;
      final email = userDoc['email'];

      // 2. Sign in with Email + Password
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Auth Error: ${e.code} - ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
