/**
 * A singleton class that manages user session information.
 * It stores user data, user permissions, and ensures that session information is consistent.
 */
class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? userId;
  Map<String, dynamic>? userData; // Store user data
  bool hasPermissions = false; // Store permission status

  /**
   * Factory constructor that returns the singleton instance of the UserSession.
   * 
   * @returns [UserSession] The singleton instance of UserSession.
   */
  factory UserSession() {
    return _instance;
  }

  /**
   * Private named constructor used to initialize the singleton instance.
   */
  UserSession._internal();

  /**
   * Loads the permission status (defaults to false).
   * This method is invoked during app restart to reset the permission status.
   * The permission status is not persisted across app restarts.
   * 
   * @returns [void]
   */
  void loadPermissions() {
    hasPermissions = false; // Always defaults to false on restart
  }

  /**
   * Saves the permission status for the current session (does not persist across app restarts).
   * 
   * @param status [bool] The permission status (true if granted, false if denied).
   * @returns [void]
   */
  void savePermissions(bool status) {
    hasPermissions = status;
  }
}
