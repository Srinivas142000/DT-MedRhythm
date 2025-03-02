class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  Map<String, dynamic>? userData; // Store user data
  bool hasPermissions = false; // Store permission status

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();

  /// Load permission status (default is false since no persistent storage)
  void loadPermissions() {
    hasPermissions = false; // Always defaults to false on restart
  }

  /// Save permission status (only persists in runtime, resets on app restart)
  void savePermissions(bool status) {
    hasPermissions = status;
  }
}
