class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final bool isVerified;
  final String role;           // ← 'admin' or 'user'

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.isVerified = false,
    this.role = 'user',        // ← default is regular user
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'phone': phone,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'isVerified': isVerified,
    'role': role,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    email: map['email'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    isVerified: map['isVerified'] ?? false,
    role: map['role'] ?? 'user',
  );

  bool get isAdmin => role == 'admin';
}