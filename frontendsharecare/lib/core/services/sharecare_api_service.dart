import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/donation_request.dart';
import '../../shared/models/donation_offer.dart';
import '../../shared/models/donation_match.dart';
import '../../shared/models/donation_transaction.dart';
import '../../shared/models/volunteer_task.dart';
import '../../shared/models/volunteer_reward.dart';
import '../../shared/models/notification_model.dart';

// Re-export for backward compatibility and shared use
export 'api_service.dart';

/// ShareCare API: auth, donations, volunteers, notifications. RESTful, grouped by module.
class ShareCareApiService {
  ShareCareApiService({ApiService? api, String? baseUrl})
    : _api = api ?? ApiService(baseUrl: baseUrl ?? ApiConstants.baseUrl);

  final ApiService _api;

  Map<String, String> _headers(Map<String, String>? auth) {
    final map = <String, String>{};
    if (auth != null) map.addAll(auth);
    return map;
  }

  // ----- Auth (api/auth/) -----
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? organization,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'role': role,
      'first_name': ?firstName,
      'last_name': ?lastName,
      'phone': ?phone,
      'organization': ?organization,
    };
    final r = await _api.post(
      '${ApiConstants.authPrefix}/register/',
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/login/',
      body: {'username': username, 'password': password},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/google/',
      body: {'id_token': idToken},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<UserModel> me(Map<String, String> authHeaders) async {
    final r = await _api.get(
      '${ApiConstants.authPrefix}/me/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return UserModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// Refresh access token using refresh token. Returns new access token or throws.
  Future<String> refreshToken(String refreshToken) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/token/refresh/',
      body: {'refresh': refreshToken},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final access = data['access'] as String?;
    if (access == null) throw ShareCareApiException(r.statusCode, r.body);
    return access;
  }

  /// Request password reset. Backend sends 6-digit OTP via email.
  Future<void> forgotPassword(String userId, String email) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/forgot-password/',
      body: {'user_id': userId, 'email': email},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Verify OTP for password reset.
  Future<void> verifyOtp(String userId, String email, String otp) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/verify-otp/',
      body: {'user_id': userId, 'email': email, 'otp': otp},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Reset password after OTP verification.
  Future<void> resetPassword(
    String userId,
    String newPassword,
    String newPasswordConfirm,
  ) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/reset-password/',
      body: {
        'user_id': userId,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  /// NGO/Hospital: submit verification ID (registration/license) for admin verification.
  Future<void> submitVerification(
    Map<String, String> authHeaders, {
    required String verificationId,
  }) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/me/submit-verification/',
      headers: _headers(authHeaders),
      body: {'verification_id': verificationId.trim()},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Change password (authenticated user).
  Future<void> changePassword(
    Map<String, String> authHeaders, {
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final r = await _api.post(
      '${ApiConstants.authPrefix}/change-password/',
      headers: _headers(authHeaders),
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      },
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Update profile (PATCH me).
  Future<UserModel> updateProfile(
    Map<String, String> authHeaders, {
    String? firstName,
    String? lastName,
    String? phone,
    String? organization,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (organization != null) body['organization'] = organization;
    final r = await _api.patch(
      '${ApiConstants.authPrefix}/me/',
      headers: _headers(authHeaders),
      body: body.isNotEmpty ? body : null,
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return UserModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// Activity history for current user (requests, offers, tasks).
  Future<List<Map<String, dynamic>>> getActivityHistory(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.authPrefix}/me/activity/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = data['results'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ----- Donations (api/donations/) -----
  Future<List<DonationRequest>> getRequests({
    Map<String, String>? authHeaders,
    String? status,
    String? category,
    String? urgency,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (category != null) params['category'] = category;
    if (urgency != null) params['urgency'] = urgency;
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/',
      headers: authHeaders != null ? _headers(authHeaders) : null,
      queryParams: params.isNotEmpty ? params : null,
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DonationRequest> getRequest(int id) async {
    final r = await _api.get('${ApiConstants.donationsPrefix}/requests/$id/');
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return DonationRequest.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<DonationRequest> createRequest(
    Map<String, String> authHeaders, {
    required String title,
    required String description,
    required String category,
    required int quantityNeeded,
    required String location,
    String urgency = 'Medium',
    double? latitude,
    double? longitude,
    Map<String, dynamic>? extraData,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'quantity_needed': quantityNeeded,
      'location': location,
      'urgency': urgency,
    };
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (extraData != null && extraData.isNotEmpty) {
      body['extra_data'] = extraData;
    }
    final r = await _api.post(
      '${ApiConstants.donationsPrefix}/requests/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationRequest.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<DonationRequest>> getMyRequests(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/my/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// NGO: list received (accepted) offers for my requests.
  Future<List<DonationOffer>> getReceivedDonations(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/received-offers/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// NGO: close a donation request (sets status to closed).
  Future<DonationRequest> closeRequest(
    Map<String, String> authHeaders,
    int requestId,
  ) async {
    final r = await _api.patch(
      '${ApiConstants.requestsPrefix}/$requestId/close/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return DonationRequest.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// NGO: update request status (open, matched, fulfilled, closed).
  Future<DonationRequest> updateRequestStatus(
    Map<String, String> authHeaders,
    int requestId, {
    required String status,
  }) async {
    final r = await _api.patch(
      '${ApiConstants.donationsPrefix}/requests/$requestId/',
      headers: _headers(authHeaders),
      body: {'status': status},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return DonationRequest.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<DonationOffer>> getOffersForRequest(
    Map<String, String> authHeaders,
    int requestId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/$requestId/offers/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DonationOffer> acceptRejectOffer(
    Map<String, String> authHeaders,
    int offerId, {
    required String status,
  }) async {
    final r = await _api.patch(
      '${ApiConstants.donationsPrefix}/offers/$offerId/accept-reject/',
      headers: _headers(authHeaders),
      body: {'status': status},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationOffer.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<DonationOffer> createOffer(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required String type,
    required int quantity,
    String? message,
    String? fulfillmentType,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    final body = <String, dynamic>{
      'donation_request': donationRequestId,
      'type': type,
      'quantity': quantity,
    };
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (fulfillmentType != null) body['fulfillment_type'] = fulfillmentType;
    if (pickupLocation != null && pickupLocation.isNotEmpty) {
      body['pickup_location'] = pickupLocation;
    }
    if (pickupLatitude != null) body['pickup_latitude'] = pickupLatitude;
    if (pickupLongitude != null) body['pickup_longitude'] = pickupLongitude;
    final r = await _api.post(
      '${ApiConstants.donationsPrefix}/offers/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationOffer.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<DonationOffer>> getMyOffers(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/offers/my/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/donations/blood-eligibility/
  Future<Map<String, dynamic>> getBloodDonationEligibility(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/blood-eligibility/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// POST /api/donations/donations/ — standalone or linked donation record.
  Future<Map<String, dynamic>> createDonationRecord(
    Map<String, String> authHeaders, {
    int? donationRequestId,
    required String category,
    required String donationType,
    required int quantity,
    String? description,
    DateTime? expiryDate,
    DateTime? validUntil,
    String? fulfillmentType,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? deliveryLocation,
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'donation_type': donationType,
      'quantity': quantity,
    };
    if (donationRequestId != null) {
      body['donation_request'] = donationRequestId;
    }
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (expiryDate != null) {
      body['expiry_date'] = expiryDate.toUtc().toIso8601String();
    }
    if (validUntil != null) {
      body['valid_until'] = validUntil.toUtc().toIso8601String();
    }
    if (fulfillmentType != null) {
      body['fulfillment_type'] = fulfillmentType;
    }
    if (pickupLocation != null && pickupLocation.isNotEmpty) {
      body['pickup_location'] = pickupLocation;
    }
    if (pickupLatitude != null) {
      body['pickup_latitude'] = pickupLatitude;
    }
    if (pickupLongitude != null) {
      body['pickup_longitude'] = pickupLongitude;
    }
    if (deliveryLocation != null && deliveryLocation.isNotEmpty) {
      body['delivery_location'] = deliveryLocation;
    }
    if (deliveryLatitude != null) {
      body['delivery_latitude'] = deliveryLatitude;
    }
    if (deliveryLongitude != null) {
      body['delivery_longitude'] = deliveryLongitude;
    }
    final res = await _api.post(
      '${ApiConstants.donationsPrefix}/donations/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(res.statusCode, res.body);
  }

  Future<List<Map<String, dynamic>>> listMyDonationRecords(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/donations/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ----- Volunteers (api/volunteers/) -----
  /// Volunteer-visible requests waiting for pickup.
  Future<List<DonationRequest>> getAvailableRequestsForVolunteer(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/available-requests/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VolunteerTask> createTask(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required String pickupLocation,
    required String deliveryLocation,
    int? donationOfferId,
  }) async {
    final body = <String, dynamic>{
      'donation_request': donationRequestId,
      'pickup_location': pickupLocation,
      'delivery_location': deliveryLocation,
    };
    if (donationOfferId != null) body['donation_offer'] = donationOfferId;
    final r = await _api.post(
      '${ApiConstants.volunteersPrefix}/tasks/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return VolunteerTask.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Pending pickup tasks (claim or decline).
  Future<List<VolunteerTask>> getPendingVolunteerTasks(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/pending-tasks/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => VolunteerTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VolunteerTask> claimVolunteerTask(
    Map<String, String> authHeaders,
    int taskId,
  ) async {
    final r = await _api.post(
      '${ApiConstants.volunteersPrefix}/tasks/$taskId/claim/',
      headers: _headers(authHeaders),
      body: const {},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return VolunteerTask.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<void> declineVolunteerTask(
    Map<String, String> authHeaders,
    int taskId,
  ) async {
    final r = await _api.post(
      '${ApiConstants.volunteersPrefix}/tasks/$taskId/decline/',
      headers: _headers(authHeaders),
      body: const {},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<VolunteerTask>> getMyTasks(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/tasks/my/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => VolunteerTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VolunteerTask> updateTask(
    Map<String, String> authHeaders,
    int taskId, {
    String? taskStatus,
  }) async {
    final body = <String, dynamic>{};
    if (taskStatus != null) body['task_status'] = taskStatus;
    final r = await _api.patch(
      '${ApiConstants.volunteersPrefix}/tasks/$taskId/',
      headers: _headers(authHeaders),
      body: body.isNotEmpty ? body : null,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return VolunteerTask.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// GET /api/volunteers/points/
  Future<VolunteerPointsSummary> getVolunteerPoints(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/points/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return VolunteerPointsSummary.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  /// GET /api/volunteers/rewards/
  Future<List<VolunteerReward>> getVolunteerRewards(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/rewards/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => VolunteerReward.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/volunteers/rewards/redeem/
  Future<RewardRedeemResult> redeemVolunteerReward(
    Map<String, String> authHeaders,
    int rewardId,
  ) async {
    final r = await _api.post(
      '${ApiConstants.volunteersPrefix}/rewards/redeem/',
      headers: _headers(authHeaders),
      body: {'reward_id': rewardId},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return RewardRedeemResult.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// GET /api/volunteers/rewards/redemptions/
  Future<List<RewardRedemption>> getVolunteerRedemptions(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.volunteersPrefix}/rewards/redemptions/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => RewardRedemption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ----- Notifications (api/notifications/) -----
  Future<List<NotificationModel>> getNotifications(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.notificationsPrefix}/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(
    Map<String, String> authHeaders,
    int id,
  ) async {
    final r = await _api.post(
      '${ApiConstants.notificationsPrefix}/$id/mark-read/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Register FCM device token for push notifications.
  Future<void> registerDeviceToken(
    Map<String, String> authHeaders,
    String token,
  ) async {
    final r = await _api.post(
      '${ApiConstants.notificationsPrefix}/register-device/',
      headers: _headers(authHeaders),
      body: {'token': token},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<void> markAllNotificationsRead(Map<String, String> authHeaders) async {
    final r = await _api.post(
      '${ApiConstants.notificationsPrefix}/mark-read/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ShareCareApiException(r.statusCode, r.body);
  }

  // ----- Payment gateway (api/payments/) -----
  /// Create Stripe PaymentIntent. Returns client_secret for Payment Sheet.
  Future<Map<String, dynamic>> createPaymentIntent(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required double amount,
    String currency = 'USD',
  }) async {
    final r = await _api.post(
      '${ApiConstants.paymentsPrefix}/create-intent/',
      headers: _headers(authHeaders),
      body: {
        'donation_request_id': donationRequestId,
        'amount': amount.toString(),
        'currency': currency,
      },
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Confirm Stripe payment after client-side success.
  Future<DonationTransaction> confirmPayment(
    Map<String, String> authHeaders, {
    required String paymentIntentId,
    required int donationRequestId,
    required double amount,
    String donationType = 'one_time',
  }) async {
    final r = await _api.post(
      '${ApiConstants.paymentsPrefix}/confirm/',
      headers: _headers(authHeaders),
      body: {
        'payment_intent_id': paymentIntentId,
        'donation_request_id': donationRequestId,
        'amount': amount.toString(),
        'donation_type': donationType,
      },
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationTransaction.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Initiate eSewa payment (Nepal). Returns form_url to open in WebView.
  Future<Map<String, dynamic>> esewaInit(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required double amountNpr,
    String donationType = 'one_time',
  }) async {
    final r = await _api.post(
      '${ApiConstants.paymentsPrefix}/esewa-init/',
      headers: _headers(authHeaders),
      body: {
        'donation_request_id': donationRequestId,
        'amount': amountNpr.toStringAsFixed(0),
        'donation_type': donationType,
      },
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Initiate eSewa Mobile SDK payment
  Future<Map<String, dynamic>> esewaMobileInit(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required double amountNpr,
    String donationType = 'one_time',
  }) async {
    final r = await _api.post(
      '${ApiConstants.paymentsPrefix}/esewa-mobile/init/',
      headers: _headers(authHeaders),
      body: {
        'donation_request_id': donationRequestId,
        'amount': amountNpr.toStringAsFixed(0),
        'donation_type': donationType,
      },
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body);
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// Confirm eSewa Mobile SDK payment
  Future<Map<String, dynamic>> esewaMobileConfirm(
    Map<String, String> authHeaders, {
    required String productId,
    required String refId,
    required double totalAmount,
  }) async {
    final r = await _api.post(
      '${ApiConstants.paymentsPrefix}/esewa-mobile/confirm/',
      headers: _headers(authHeaders),
      body: {
        'product_id': productId,
        'ref_id': refId,
        'total_amount': totalAmount.toString(),
      },
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body);
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// GET /api/payments/history/ - Payment transactions (gateway).
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.paymentsPrefix}/history/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ----- Donation payments & history (api/donations/) -----
  Future<List<DonationTransaction>> getDonationHistory(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/history/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DonationTransaction> donationPay(
    Map<String, String> authHeaders, {
    required int donationRequestId,
    required double amount,
    String donationType = 'one_time',
    String? paymentReference,
  }) async {
    final body = <String, dynamic>{
      'donation_request_id': donationRequestId,
      'amount': amount.toString(),
      'donation_type': donationType,
      'payment_reference': ?paymentReference,
    };
    final r = await _api.post(
      '${ApiConstants.donationsPrefix}/pay/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationTransaction.fromJson(
        jsonDecode(r.body) as Map<String, dynamic>,
      );
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// GET /api/donations/recommendations/ - Recommended campaigns (matchmaking).
  Future<List<DonationRequest>> getRecommendations(
    Map<String, String> authHeaders, {
    String? category,
    String? location,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (location != null) params['location'] = location;
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/recommendations/',
      headers: _headers(authHeaders),
      queryParams: params.isNotEmpty ? params : null,
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/donations/matches/my/ - Matchmaking cards for the current user.
  Future<List<DonationMatch>> getMyMatches(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/matches/my/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .map((e) => DonationMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /api/donations/matches/:id/respond/
  Future<DonationMatch> respondToMatch(
    Map<String, String> authHeaders, {
    required int matchId,
    required String response, // "accepted" | "rejected"
  }) async {
    final r = await _api.patch(
      '${ApiConstants.donationsPrefix}/matches/$matchId/respond/',
      headers: _headers(authHeaders),
      body: {'response': response},
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return DonationMatch.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// GET /api/donations/stats/ - Real-time analytics for dashboard charts.
  Future<Map<String, dynamic>> getDonationStats(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/stats/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// GET /api/donations/requests/:id/progress/ - Campaign progress.
  Future<Map<String, dynamic>> getCampaignProgress(
    Map<String, String> authHeaders,
    int requestId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/$requestId/progress/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// POST /api/impact/create/ - Create impact update.
  Future<Map<String, dynamic>> createImpactUpdate(
    Map<String, String> authHeaders, {
    required int campaignId,
    required String title,
    required String description,
    List<String>? images,
    int peopleHelped = 0,
  }) async {
    final body = <String, dynamic>{
      'campaign_id': campaignId,
      'title': title,
      'description': description,
      'people_helped': peopleHelped,
      'images': ?images,
    };
    final r = await _api.post(
      '${ApiConstants.apiPrefix}/impact/create/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  /// POST /api/campaigns/upload-media/ - Upload campaign image.
  Future<Map<String, dynamic>> uploadCampaignMedia(
    Map<String, String> authHeaders, {
    required int campaignId,
    required List<int> imageBytes,
    required String fileName,
    bool isPrimary = true,
  }) async {
    const path = '/api/campaigns/upload-media/';
    final request = await _api.multipartPost(
      path,
      headers: _headers(authHeaders),
      fields: {
        'campaign_id': campaignId.toString(),
        'is_primary': isPrimary.toString(),
      },
      files: {
        'image': http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      },
    );
    if (request.statusCode >= 200 && request.statusCode < 300) {
      return jsonDecode(request.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(request.statusCode, request.body);
  }

  /// GET /api/impact/campaign/:id/ - Impact updates for campaign.
  Future<List<Map<String, dynamic>>> getImpactUpdates(
    Map<String, String> authHeaders,
    int campaignId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.apiPrefix}/impact/campaign/$campaignId/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// GET /api/donations/requests/:id/updates/ - Campaign updates.
  Future<List<Map<String, dynamic>>> getCampaignUpdates(
    Map<String, String> authHeaders,
    int requestId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/$requestId/updates/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Download receipt PDF for a donation (by request id - user's latest for that campaign).
  Future<List<int>> downloadReceiptForRequest(
    Map<String, String> authHeaders,
    int requestId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.donationsPrefix}/requests/$requestId/receipt/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return r.bodyBytes;
  }

  /// Download receipt PDF for a transaction.
  Future<List<int>> downloadReceiptForTransaction(
    Map<String, String> authHeaders,
    int transactionId,
  ) async {
    final r = await _api.get(
      '${ApiConstants.paymentsPrefix}/transactions/$transactionId/receipt/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return r.bodyBytes;
  }

  // ----- Admin (api/admin/) -----
  Future<Map<String, dynamic>> getAdminDashboard(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.adminPrefix}/dashboard/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminAnalytics(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.adminPrefix}/analytics/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminVerificationList(
    Map<String, String> authHeaders, {
    String? status,
  }) async {
    final params = status != null ? <String, String>{'status': status} : null;
    final r = await _api.get(
      '${ApiConstants.adminPrefix}/verification/',
      headers: _headers(authHeaders),
      queryParams: params,
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> approveNgo(
    Map<String, String> authHeaders,
    int profileId, {
    required String action,
    String? notes,
  }) async {
    final r = await _api.post(
      '${ApiConstants.adminPrefix}/approve-ngo/$profileId/',
      headers: _headers(authHeaders),
      body: {'action': action, 'notes': ?notes},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<Map<String, dynamic>>> getAdminUsers(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.adminPrefix}/users/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getActivityLogs(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.adminPrefix}/logs/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ----- Support (api/support/) -----
  Future<Map<String, dynamic>> createSupportTicket(
    Map<String, String> authHeaders, {
    required String subject,
    required String message,
    String? category,
  }) async {
    final body = <String, dynamic>{
      'subject': subject,
      'message': message,
      'category': ?category,
    };
    final r = await _api.post(
      '${ApiConstants.supportPrefix}/tickets/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<Map<String, dynamic>>> getMySupportTickets(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.supportPrefix}/tickets/my/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getFaq(
    Map<String, String>? authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.supportPrefix}/faq/',
      headers: authHeaders != null ? _headers(authHeaders) : null,
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final list = data['results'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ----- Messages (api/messages/) -----

  Future<List<Map<String, dynamic>>> getConversations(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.messagesPrefix}/conversations/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createConversation(
    Map<String, String> authHeaders, {
    required int otherUserId,
  }) async {
    final r = await _api.post(
      '${ApiConstants.messagesPrefix}/conversations/create/',
      headers: _headers(authHeaders),
      body: {'other_user_id': otherUserId},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Chat API alias: create/get room between two users.
  Future<Map<String, dynamic>> getOrCreateChatRoom(
    Map<String, String> authHeaders, {
    required int otherUserId,
  }) async {
    final r = await _api.post(
      '${ApiConstants.chatPrefix}/room/',
      headers: _headers(authHeaders),
      body: {'other_user_id': otherUserId},
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getChatRooms(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.chatPrefix}/rooms/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Users you can message (donation/volunteer context + existing rooms).
  Future<List<Map<String, dynamic>>> getChatPartners(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      '${ApiConstants.chatPrefix}/partners/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getChatMessages(
    Map<String, String> authHeaders, {
    required int roomId,
  }) async {
    final r = await _api.get(
      '${ApiConstants.chatPrefix}/messages/$roomId/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> sendChatMessage(
    Map<String, String> authHeaders, {
    required int roomId,
    required String text,
    int? requestId,
    int? donationId,
  }) async {
    final body = <String, dynamic>{'room_id': roomId, 'text': text};
    if (requestId != null) body['request_id'] = requestId;
    if (donationId != null) body['donation_id'] = donationId;
    final r = await _api.post(
      '${ApiConstants.chatPrefix}/send/',
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> markChatRead(
    Map<String, String> authHeaders, {
    required int roomId,
  }) async {
    final r = await _api.post(
      '${ApiConstants.chatPrefix}/read/',
      headers: _headers(authHeaders),
      body: {'room_id': roomId},
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
  }

  Future<List<Map<String, dynamic>>> getMessages(
    Map<String, String> authHeaders, {
    required int conversationId,
  }) async {
    final r = await _api.get(
      '${ApiConstants.messagesPrefix}/conversations/$conversationId/messages/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    Map<String, String> authHeaders, {
    required int conversationId,
    required String text,
  }) async {
    final r = await _api.post(
      '${ApiConstants.messagesPrefix}/conversations/$conversationId/messages/',
      headers: _headers(authHeaders),
      body: {'text': text},
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> markMessagesRead(
    Map<String, String> authHeaders, {
    required int conversationId,
  }) async {
    await _api.post(
      '${ApiConstants.messagesPrefix}/conversations/$conversationId/mark-read/',
      headers: _headers(authHeaders),
      body: {},
    );
  }

  // ----- Peer-to-Peer Donations -----
  Future<List<dynamic>> getP2PDonations(Map<String, String> auth) async {
    final r = await _api.get(
      '/api/donations/p2p-donations/',
      headers: _headers(auth),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    final data = jsonDecode(r.body);
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createP2PDonation(
    Map<String, String> auth,
    Map<String, dynamic> body,
  ) async {
    final r = await _api.post(
      '/api/donations/p2p-donations/',
      body: body,
      headers: _headers(auth),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getP2PDonationDetail(
    String id,
    Map<String, String> auth,
  ) async {
    final r = await _api.get(
      '/api/donations/p2p-donations/$id/',
      headers: _headers(auth),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateP2PDonationStatus(
    String id,
    String action,
    Map<String, String> auth,
  ) async {
    final r = await _api.post(
      '/api/donations/p2p-donations/$id/$action/',
      body: {},
      headers: _headers(auth),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ----- Life donations (blood registration, organ pledge) -----

  Future<Map<String, dynamic>> getLifeBloodStatus(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      ApiConstants.lifeBloodStatus,
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitLifeBloodDonation(
    Map<String, String> authHeaders,
    Map<String, dynamic> body,
  ) async {
    final r = await _api.post(
      ApiConstants.lifeBloodRegister,
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLifeOrganStatus(
    Map<String, String> authHeaders,
  ) async {
    final r = await _api.get(
      ApiConstants.lifeOrganStatus,
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitLifeOrganPledge(
    Map<String, String> authHeaders,
    Map<String, dynamic> body,
  ) async {
    final r = await _api.post(
      ApiConstants.lifeOrganPledge,
      headers: _headers(authHeaders),
      body: body,
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ShareCareApiException(r.statusCode, r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

class ShareCareApiException implements Exception {
  ShareCareApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  String get message {
    try {
      final json = jsonDecode(body);
      final parts = <String>[];
      if (json is Map) {
        if (json.containsKey('detail')) parts.add(json['detail'].toString());
        if (json.containsKey('error')) parts.add(json['error'].toString());
        for (final k in json.keys) {
          if (k != 'detail' && k != 'error') {
            parts.add('$k: ${json[k]}');
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('; ');
      return body.isNotEmpty ? body : 'Request failed ($statusCode)';
    } catch (_) {
      return body.isNotEmpty ? body : 'Request failed ($statusCode)';
    }
  }

  @override
  String toString() => 'ShareCareApiException($statusCode): $body';
}
