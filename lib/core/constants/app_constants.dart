class AppConstants {
  static const String appName = 'QR Master';
  static const String appTagline = 'Scan • Create • Manage';

  // Splash
  static const String splashLoading = 'Loading...';
  static const String splashScanCreateManage = 'Scan • Create • Manage';
  static const String splashVersionPrefix = 'Version';
  static const Duration splashMinDuration = Duration(seconds: 2);

  // Onboarding
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get Started';

  // Home
  static const String homeWelcome = 'Welcome';
  static const String homeSubtitle = 'Manage your QR codes easily';
  static const String homeRecentActivity = 'Recent Activity';
  static const String homeNoRecentActivity = 'No recent activity yet';

  // Quick Actions
  static const String actionScanQr = 'Scan QR';
  static const String descScanQr = "Quick Scan";
  static const String actionCreateQr = 'Create QR';
  static const String descCreateQr = "Generate New";
  static const String actionMyQrCodes = 'My QR Codes';
  static const String descMyQR = "Saved Codes";
  static const String actionHistory = 'History';
  static const String descHistory = "Rescent Scans";

  // Scan result modal
  static const String scanSuccessfulTitle = 'Scan Successful';
  static const String scanSuccessfulSubtitle = 'QR code decoded successfully';
  static const String fullContent = 'Full Content';
  static const String modalOpen = 'Open';
  static const String modalOpenLink = 'Open Link';
  static const String modalCopy = 'Copy';
  static const String modalShare = 'Share';
  static const String modalSave = 'Save';
  static const String modalAddToContacts = 'Add to Contacts';
  static const String modalConnectToWifi = 'Connect to WiFi';
  static const String modalCopied = 'Copied to clipboard';
  static const String modalSaved = 'Saved to My QR Codes';
  static const String modalSaveFailed = 'Unable to save';
  static const String modalContactSaved = 'Contact saved';
  static const String modalWifiConnectStarted = 'Connecting to WiFi...';

  // Routes
  static const String routeSplash = '/splash';
  static const String routeOnboarding = '/onboarding';
  static const String routeHome = '/home';
  static const String routeScanner = '/scanner';
  static const String routeScanResult = '/scan-result';
  static const String routeCreateQr = '/create-qr';
  static const String routeGeneratedQr = '/generated-qr';
  static const String routeMyQrCodes = '/my-qr-codes';
  static const String routeHistory = '/history';
  static const String routePaywall = '/paywall';

  // Hive boxes
  static const String boxHistory = 'history';
  static const String boxMyQrCodes = 'my_qr_codes';
  static const String boxSettings = 'settings';

  // Settings keys
  static const String keyOnboardingShown = 'onboarding_shown';

  // Limits
  static const int historyMaxItems = 200;
}

