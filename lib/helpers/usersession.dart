class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  Map<String, dynamic>? userData;
  bool hasPermissions = false;

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();
}
