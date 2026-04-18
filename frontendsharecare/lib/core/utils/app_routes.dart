class AppRoutes {
  AppRoutes._();

  // Auth & main
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';

  // Donations (shared)
  static const String requestDetail = '/request-detail';
  static const String createRequest = '/create-request';
  static const String createDonation = '/create-donation';
  static const String standaloneDonation = '/donations/standalone';
  static const String p2pDonations = '/p2p-donations';
  static const String offerDonation = '/offer-donation';
  static const String myOffers = '/my-offers';
  static const String categoryRequests = '/category-requests';
  static const String browseDonationRequests = '/donations/browse';
  static const String donationMap = '/donations/map';
  static const String categoryListing = '/donations/categories';
  static const String searchFilter = '/donations/search-filter';
  static const String donationHistory = '/donations/history';
  static const String requestHistory = '/ngo/request-history';
  static const String emptyState = '/empty';

  // Specific Direct Donation Routes (Cleaned up)
  static const String itemDonation = '/donate/items';
  static const String fundsDonation = '/donate/funds';
  static const String lifeDonations = '/donations/life-donations';
  static const String bloodDonation = '/donations/blood';
  static const String organDonation = '/donations/organ';

  // Volunteer
  static const String volunteerAcceptTask = '/volunteer-accept-task';
  static const String volunteerTasks = '/volunteer-tasks';
  static const String volunteerMap = '/volunteer/map';
  static const String taskDetails = '/volunteer/task-details';
  static const String updateTaskStatus = '/volunteer/update-task-status';
  static const String deliveryTaskTracking = '/volunteer/delivery-tracking';
  static const String taskHistory = '/volunteer/task-history';

  // NGO
  static const String manageMyRequests = '/ngo/manage-requests';
  static const String ngoRequestDetails = '/ngo/request-details';
  static const String receivedDonations = '/ngo/received-donations';
  static const String ngoVerification = '/ngo/verification';

  // Admin
  static const String verifyOrganizations = '/admin/verify-organizations';
  static const String manageUsers = '/admin/manage-users';
  static const String reportsAnalytics = '/admin/reports';
  static const String activityLogs = '/admin/activity-logs';

  // Profile
  static const String viewProfile = '/profile/view';
  // Profile & settings
  static const String editProfile = '/edit-profile';
  static const String activityHistory = '/activity-history';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String notificationPreferences = '/notification-preferences';
  static const String helpSupport = '/help-support';
  static const String faq = '/faq';
  static const String aboutShareCare = '/about-sharecare';
  static const String contactSupport = '/contact-support';
  static const String myTickets = '/my-tickets';
  static const String conversations = '/conversations';
  static const String chatList = '/chat-list';
  static const String chatRoom = '/chat-room';
  static const String chat = '/chat';
  static const String notifications = '/notifications';

  // Extra Donations routes
  static const String foodDonation = '/donations/food';
  static const String clothesDonation = '/donations/clothes';
  static const String otherDonation = '/donations/other';
  static const String donateItems = '/donate-items';
  static const String donateFunds = '/donate-funds';
  static const String donateBrowse = '/donate-browse';
}
