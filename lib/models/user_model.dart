class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'student'
  final String? studentId; // Only for students
  final double balance; // Only for students
  final String busPassStatus; // 'none', 'pending', 'approved', 'rejected'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.balance = 0.0,
    this.busPassStatus = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'balance': balance,
      'bus_pass_status': busPassStatus,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      studentId: map['studentId'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      busPassStatus: map['bus_pass_status'] ?? 'none',
    );
  }
}
