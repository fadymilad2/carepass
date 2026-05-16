class AppConstants {
  AppConstants._();
 
  // App Info
  static const String appName        = 'CarePass';
  static const String appVersion     = '1.0.0';
  static const String appDescription = 'Quality Care for Less';
 
  // Firebase Collections
  static const String usersCollection        = 'users';
  static const String providersCollection    = 'providers';
  static const String servicesCollection     = 'services';
  static const String subscriptionsCollection = 'subscriptions';
  static const String paymentsCollection     = 'payments';
  static const String notificationsCollection = 'notifications';
  static const String areasCollection        = 'areas';
  static const String checkupsCollection     = 'checkups';
 
  // Cloud Functions
  static const String fnCreatePayment    = 'createMomoPayment';
  static const String fnVerifyPayment    = 'verifyMomoPayment';
  static const String fnAiAssistant      = 'aiHealthAssistant';
  static const String fnSendNotification = 'sendNotification';
 
  // Subscription Plans
  static const String planStandard  = 'standard';
  static const String planPremium   = 'premium';
  static const String planFamily    = 'family';
 
  // Plan Prices (USD)
  static const double priceStandard = 14.99;
  static const double pricePremium  = 24.99;
  static const double priceFamily   = 39.99;
  static const double vatRate       = 0.05; // 5%
 
  // Card Status
  static const String statusActive   = 'active';
  static const String statusExpired  = 'expired';
  static const String statusPending  = 'pending';
  static const String statusSuspended = 'suspended';
 
  // Storage Keys
  static const String keyOnboarding  = 'onboarding_done';
  static const String keyUserToken   = 'user_token';
  static const String keySelectedArea = 'selected_area';
  static const String keyThemeMode   = 'theme_mode';
 
  // Pagination
  static const int pageSize = 20;
 
  // Timeouts
  static const Duration connectTimeout   = Duration(seconds: 15);
  static const Duration receiveTimeout   = Duration(seconds: 30);
  static const Duration cacheExpiry      = Duration(hours: 1);
}