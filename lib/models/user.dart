class User {
  final String uid;
  final String username;
  final String email;

  User({
    required this.uid,
    required this.username,
    required this.email, required String phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '', phoneNumber: '',
    );
  }
}
