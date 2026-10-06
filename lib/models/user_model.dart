class UserModel {
  final String uid;
  final String username;
  final String email;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toMap() => {'username': username, 'email': email};

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      username: map['username'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
    );
  }
}
