import 'package:flutter_test/flutter_test.dart';
import 'package:frontendsharecare/core/constants/api_constants.dart';
import 'package:frontendsharecare/core/services/sharecare_api_service.dart';

import 'helpers/fake_api_service.dart';
import 'helpers/feature_helpers.dart';

void main() {
  group('Offer donation flow', () {
    late FakeApiService fakeApi;
    late ShareCareApiService service;

    const authHeaders = <String, String>{'Authorization': 'Bearer mock-token'};

    setUp(() {
      fakeApi = FakeApiService();
      service = ShareCareApiService(api: fakeApi);
    });

    test('validates offer payload input fields', () {
      // Ensure required offer inputs are validated before submission.
      expect(
        validateOfferInput(donationRequestId: 0, type: 'food', quantity: 2),
        'Donation request id is required.',
      );
      expect(
        validateOfferInput(donationRequestId: 4, type: '', quantity: 2),
        'Offer type is required.',
      );
      expect(
        validateOfferInput(donationRequestId: 4, type: 'food', quantity: 0),
        'Offer quantity must be greater than zero.',
      );
    });

    test('creates donation offer and sends expected payload', () async {
      // Mock successful offer creation.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.donationsPrefix}/offers/',
        statusCode: 201,
        jsonBody: <String, dynamic>{
          'id': 700,
          'donation_request': 9,
          'type': 'food',
          'quantity': 10,
          'status': 'pending',
          'message': 'Can deliver today',
          'fulfillment_type': 'volunteer_pickup',
        },
      );

      final offer = await service.createOffer(
        authHeaders,
        donationRequestId: 9,
        type: 'food',
        quantity: 10,
        message: 'Can deliver today',
        fulfillmentType: 'volunteer_pickup',
      );

      final request = fakeApi.lastRequest(
        'POST',
        '${ApiConstants.donationsPrefix}/offers/',
      );
      final body = requestBodyAsMap(request);

      expect(offer.id, 700);
      expect(offer.status, 'pending');
      expect(body['donation_request'], 9);
      expect(body['type'], 'food');
      expect(body['quantity'], 10);
      expect(body['message'], 'Can deliver today');
      expect(body['fulfillment_type'], 'volunteer_pickup');
    });

    test('throws ShareCareApiException on offer API failure', () async {
      // Mock authorization failure for offer submission.
      fakeApi.queueJsonResponse(
        method: 'POST',
        path: '${ApiConstants.donationsPrefix}/offers/',
        statusCode: 403,
        jsonBody: <String, dynamic>{'detail': 'Not allowed to offer'},
      );

      expect(
        () => service.createOffer(
          authHeaders,
          donationRequestId: 9,
          type: 'food',
          quantity: 10,
        ),
        throwsA(
          isA<ShareCareApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });
}
