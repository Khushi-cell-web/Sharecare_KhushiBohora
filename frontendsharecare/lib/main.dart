import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/constants/api_constants.dart';
import 'core/services/notification_service.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'core/utils/app_routes.dart';
import 'core/utils/page_transitions.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/category_listing_screen.dart';
import 'screens/category_requests_screen.dart';
import 'screens/create_ngo_request_screen.dart';
import 'screens/item_donation_screen.dart';
import 'screens/category_donation/funds_donation_screen.dart';
import 'screens/create_donation_screen.dart';
import 'screens/donation_history_screen.dart';
import 'screens/leaflet_donation_map_screen.dart';
import 'screens/life_donations_screen.dart';
import 'screens/blood_donation_screen.dart';
import 'screens/organ_donation_screen.dart';
import 'shared/models/donation_request.dart' as shared_dr;
import 'features/donations/screens/offer_donation_screen.dart';
import 'features/donations/screens/standalone_donation_screen.dart';
import 'features/donations/screens/p2p_donations_list_screen.dart';
import 'features/donations/models/donation_request.dart' as feat_dr;
import 'screens/empty_state_screen.dart';
import 'screens/my_offers_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/request_history_screen.dart';
import 'screens/search_filter_screen.dart';
import 'screens/volunteer_accept_task_screen.dart';
import 'screens/volunteer_tasks_screen.dart';

import 'features/admin/screens/activity_logs_screen.dart';
import 'features/admin/screens/manage_users_screen.dart';
import 'features/admin/screens/reports_analytics_screen.dart';
import 'features/admin/screens/verify_organizations_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/verify_otp_screen.dart';
import 'features/donations/screens/browse_donation_requests_screen.dart';
import 'features/ngo/screens/manage_my_requests_screen.dart';
import 'features/ngo/screens/ngo_verification_screen.dart';
import 'features/ngo/screens/received_donations_screen.dart';
import 'features/ngo/screens/request_details_ngo_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/screens/activity_history_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/view_profile_screen.dart';
import 'features/settings/screens/change_password_screen.dart';
import 'features/settings/screens/notification_preferences_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/support/screens/about_screen.dart';
import 'features/support/screens/contact_support_screen.dart';
import 'features/support/screens/faq_screen.dart';
import 'features/support/screens/help_support_screen.dart';
import 'features/support/screens/my_tickets_screen.dart';
import 'features/messages/chat_list_screen.dart';
import 'features/messages/chat_room_screen.dart';
import 'features/volunteers/screens/task_details_screen.dart';
import 'features/volunteers/screens/task_history_screen.dart';
import 'features/volunteers/screens/update_task_status_screen.dart';
import 'features/volunteers/screens/delivery_task_tracking_screen.dart';
import 'features/volunteers/screens/leaflet_volunteer_task_map_screen.dart';
import 'shared/models/volunteer_task.dart';

void _registerWebViewPlatform() {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerWebViewPlatform();
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // .env not found; Stripe will use mock
  }
  await ApiConstants.initialize();
  if (kDebugMode) {
    debugPrint('ShareCare API base URL: ${ApiConstants.resolvedBaseUrl}');
  }
  ApiConstants.setStripeKey(AppConfig.stripePublishableKey);
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
  } catch (_) {
    // Firebase not configured (e.g. missing google-services.json)
  }
  final key = ApiConstants.stripePublishableKey;
  if (key.isNotEmpty && !key.contains('placeholder')) {
    Stripe.publishableKey = key;
    try {
      await Stripe.instance.applySettings();
    } catch (_) {
      // Native PaymentConfiguration may fail if key invalid; payment screen will show message
    }
  }
  runApp(const ShareCareApp());
}

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ShareCareApp extends StatelessWidget {
  const ShareCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFcmForegroundHandlers();
    });
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadTokens()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: 'ShareCare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.home,
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }
}

void _setupFcmForegroundHandlers() {
  NotificationService.configureHandlers(
    onMessage: (message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(body.isNotEmpty ? '$title: $body' : title),
          duration: const Duration(seconds: 4),
        ),
      );
    },
    onMessageOpenedApp: (_) {
      // User tapped notification; could navigate to relevant screen
    },
  );
}

Route<dynamic>? _generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.donateItems:
      return MaterialPageRoute(builder: (_) => const ItemDonationScreen());
    case AppRoutes.donateFunds:
    case AppRoutes.fundsDonation:
      return MaterialPageRoute(builder: (_) => const FundsDonationScreen());
    case AppRoutes.foodDonation:
      return MaterialPageRoute(
        builder: (_) => const CategoryRequestsScreen(
          categoryKey: 'food',
          categoryLabel: 'Food',
          subtitle: 'Dry food, cooked meals, baby food',
        ),
      );
    case AppRoutes.clothesDonation:
      return MaterialPageRoute(
        builder: (_) => const CategoryRequestsScreen(
          categoryKey: 'clothes',
          categoryLabel: 'Clothes',
          subtitle: 'Men, women, children',
        ),
      );
    case AppRoutes.otherDonation:
      return MaterialPageRoute(
        builder: (_) => const CategoryRequestsScreen(
          categoryKey: 'other',
          categoryLabel: 'Other',
          subtitle: 'Other items',
        ),
      );
    case AppRoutes.donateBrowse:
      return MaterialPageRoute(
        builder: (_) => const BrowseDonationRequestsScreen(),
      );
    case AppRoutes.lifeDonations:
      return MaterialPageRoute(builder: (_) => const LifeDonationsScreen());
    case AppRoutes.bloodDonation:
      return MaterialPageRoute(builder: (_) => const BloodDonationScreen());
    case AppRoutes.organDonation:
      return MaterialPageRoute(builder: (_) => const OrganDonationScreen());

    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const AuthGateScreen());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    case AppRoutes.forgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    case AppRoutes.verifyOtp:
      final args = settings.arguments as Map<String, dynamic>?;
      final email = args?['email'] as String?;
      final userId = args?['userId'] as String?;
      if (email == null || userId == null) {
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      }
      return MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(userId: userId, email: email),
      );
    case AppRoutes.resetPassword:
      final args = settings.arguments as Map<String, dynamic>?;
      final email = args?['email'] as String?;
      final userId = args?['userId'] as String?;
      if (email == null || userId == null) {
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      }
      return MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(userId: userId, email: email),
      );
    case AppRoutes.requestDetail:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RequestDetailScreen(),
      );
    case AppRoutes.createRequest:
      return MaterialPageRoute(builder: (_) => const CreateNgoRequestScreen());
    case '/ngo/create-request':
      return MaterialPageRoute(builder: (_) => const CreateNgoRequestScreen());
    case AppRoutes.createDonation:
      return PageTransitions.slideTransition(const CreateDonationScreen());
    case AppRoutes.offerDonation:
      final arg = settings.arguments;
      if (arg is shared_dr.DonationRequest) {
        final model = feat_dr.DonationRequestModel.fromDonationRequest(arg);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OfferDonationScreen(request: model),
        );
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const BrowseDonationRequestsScreen(),
      );
    case AppRoutes.standaloneDonation:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const StandaloneDonationScreen(),
      );
    case AppRoutes.volunteerAcceptTask:
      return MaterialPageRoute(
        builder: (_) => const VolunteerAcceptTaskScreen(),
      );
    case AppRoutes.volunteerTasks:
      return MaterialPageRoute(builder: (_) => const VolunteerTasksScreen());
    case AppRoutes.myOffers:
      return MaterialPageRoute(builder: (_) => const MyOffersScreen());
    case AppRoutes.p2pDonations:
      return MaterialPageRoute(builder: (_) => const P2PDonationsListScreen());
    case AppRoutes.notifications:
      return PageTransitions.slideTransition(const NotificationsScreen());
    case AppRoutes.browseDonationRequests:
      return MaterialPageRoute(
        builder: (_) => const BrowseDonationRequestsScreen(),
      );
    case AppRoutes.donationMap:
      return MaterialPageRoute(
        builder: (_) => const LeafletDonationMapScreen(),
      );
    case AppRoutes.manageMyRequests:
      return MaterialPageRoute(builder: (_) => const ManageMyRequestsScreen());
    case AppRoutes.ngoRequestDetails:
      return MaterialPageRoute(
        builder: (_) => RequestDetailsNgoScreen(
          request: settings.arguments as Map<String, dynamic>? ?? {},
        ),
      );
    case AppRoutes.receivedDonations:
      return MaterialPageRoute(builder: (_) => const ReceivedDonationsScreen());
    case AppRoutes.ngoVerification:
      return MaterialPageRoute(builder: (_) => const NgoVerificationScreen());
    case AppRoutes.taskDetails:
      return MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: settings.arguments as Map<String, dynamic>?,
        ),
      );
    case AppRoutes.updateTaskStatus:
      return MaterialPageRoute(
        builder: (_) => UpdateTaskStatusScreen(
          task: settings.arguments as Map<String, dynamic>?,
        ),
      );
    case AppRoutes.deliveryTaskTracking:
      final tid = settings.arguments as int?;
      if (tid == null) {
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
      }
      return MaterialPageRoute(
        builder: (_) => DeliveryTaskTrackingScreen(taskId: tid),
      );
    case AppRoutes.taskHistory:
      return MaterialPageRoute(builder: (_) => const TaskHistoryScreen());
    case AppRoutes.volunteerMap:
      final task = settings.arguments as VolunteerTask?;
      if (task == null) {
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
      }
      return MaterialPageRoute(
        builder: (_) => LeafletVolunteerTaskMapScreen(task: task),
      );
    case AppRoutes.verifyOrganizations:
      return MaterialPageRoute(
        builder: (_) => const VerifyOrganizationsScreen(),
      );
    case AppRoutes.manageUsers:
      return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
    case AppRoutes.reportsAnalytics:
      return MaterialPageRoute(builder: (_) => const ReportsAnalyticsScreen());
    case AppRoutes.activityLogs:
      return MaterialPageRoute(builder: (_) => const ActivityLogsScreen());
    case AppRoutes.viewProfile:
      return MaterialPageRoute(builder: (_) => const ViewProfileScreen());
    case AppRoutes.editProfile:
      return MaterialPageRoute(builder: (_) => const EditProfileScreen());
    case AppRoutes.activityHistory:
      return MaterialPageRoute(builder: (_) => const ActivityHistoryScreen());
    case AppRoutes.settings:
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case AppRoutes.changePassword:
      return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
    case AppRoutes.notificationPreferences:
      return MaterialPageRoute(
        builder: (_) => const NotificationPreferencesScreen(),
      );
    case AppRoutes.helpSupport:
      return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
    case AppRoutes.faq:
      return MaterialPageRoute(builder: (_) => const FaqScreen());
    case AppRoutes.aboutShareCare:
      return MaterialPageRoute(builder: (_) => const AboutScreen());
    case AppRoutes.contactSupport:
      return MaterialPageRoute(builder: (_) => const ContactSupportScreen());
    case AppRoutes.myTickets:
      return MaterialPageRoute(builder: (_) => const MyTicketsScreen());
    case AppRoutes.conversations:
    case AppRoutes.chatList:
      return MaterialPageRoute(builder: (_) => const ChatListScreen());
    case AppRoutes.chatRoom:
      final roomScreen = ChatRoomScreen.fromArguments(settings.arguments);
      if (roomScreen == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Chat'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Unable to open chat')),
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => roomScreen);
    case AppRoutes.chat:
      final legacyRoom = ChatRoomScreen.fromArguments(settings.arguments);
      if (legacyRoom == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Chat'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Unable to open chat')),
          ),
        );
      }
      return MaterialPageRoute(builder: (_) => legacyRoom);
    case AppRoutes.categoryListing:
      return MaterialPageRoute(builder: (_) => const CategoryListingScreen());
    case AppRoutes.categoryRequests:
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CategoryRequestsScreen(
          categoryKey: args?['categoryKey'] as String? ?? 'other',
          categoryLabel: args?['categoryLabel'] as String? ?? 'Donations',
          subtitle: args?['subtitle'] as String?,
        ),
      );
    case AppRoutes.searchFilter:
      return MaterialPageRoute(builder: (_) => const SearchFilterScreen());
    case AppRoutes.donationHistory:
      return MaterialPageRoute(builder: (_) => const DonationHistoryScreen());
    case AppRoutes.requestHistory:
      return MaterialPageRoute(builder: (_) => const RequestHistoryScreen());
    case AppRoutes.emptyState:
      final emptyArgs = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => EmptyStateScreen(
          showBackButton: emptyArgs?['showBackButton'] as bool? ?? true,
          title: emptyArgs?['message'] as String? ?? 'Nothing here',
          subtitle: emptyArgs?['subtitle'] as String?,
          isError: emptyArgs?['isError'] as bool? ?? false,
        ),
      );

    default:
      return MaterialPageRoute(builder: (_) => const AuthGateScreen());
  }
}
