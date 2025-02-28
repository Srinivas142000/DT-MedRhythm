class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  Map<String, dynamic>? userData; // Store user data

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();
}
