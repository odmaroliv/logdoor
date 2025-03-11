class AppConstants {
  // API URLs
  static const String baseUrl = 'https://api.logdoor.com';
  static const String apiVersion = 'v1';

  // Shared Preferences Keys
  static const String languagePrefKey = 'app_language';
  static const String themePrefKey = 'app_theme';
  static const String userIdKey = 'user_id';
  static const String accessTokenKey = 'access_token';

  // CTPAT Configuration
  static const int inspectionPhotoMinCount = 1;
  static const int inspectionPhotoMaxCount = 5;

  // Offline Sync Configuration
  static const int syncIntervalMinutes = 15;
  static const int maxOfflineStorageMB = 100;

  // Timeouts
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
}
