class AppConstants {
  // API Configuration
  static const String baseApiUrl = 'https://gomanga-api.vercel.app/api';
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // App Information
  static const String appName = 'Manga Cat';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Discover Amazing Stories';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRetryAttempts = 3;
  
  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100; // MB
  
  // UI Settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Reader Settings
  static const double minZoomScale = 0.5;
  static const double maxZoomScale = 3.0;
  static const double defaultZoomScale = 1.0;
  
  // Network
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String themePreferenceKey = 'theme_preference';
  static const String readingHistoryKey = 'reading_history';
  static const String favoritesKey = 'favorites';
  static const String readerSettingsKey = 'reader_settings';
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again';
  static const String serverErrorMessage = 'Server error occurred. Please try again later';
  static const String unknownErrorMessage = 'An unexpected error occurred';
  static const String noDataMessage = 'No data available';
  
  // Success Messages
  static const String dataLoadedMessage = 'Data loaded successfully';
  static const String searchCompletedMessage = 'Search completed';
  
  // Feature Flags
  static const bool enableOfflineReading = false;
  static const bool enableDownloads = false;
  static const bool enableUserAccounts = false;
  static const bool enableSocialFeatures = false;
  
  // Limits
  static const int maxSearchHistory = 10;
  static const int maxFavorites = 1000;
  static const int maxReadingHistory = 500;
}