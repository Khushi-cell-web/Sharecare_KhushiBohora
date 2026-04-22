from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.donations.models import DonationOffer, DonationRequest
from apps.notifications.models import DeviceToken, Notification
from apps.support.models import SupportTicket
from apps.users.models import UserProfile
from apps.volunteers.models import VolunteerTask


class MainFeaturesApiTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()

        self.donor = user_model.objects.create_user(
            username="donor_main",
            email="donor_main@example.com",
            password="Donor@12345",
            role="donor",
        )
        self.ngo = user_model.objects.create_user(
            username="ngo_main",
            email="ngo_main@example.com",
            password="Ngo@12345",
            role="ngo",
            organization="Helping Hands",
            first_name="NGO",
            last_name="Owner",
        )
        self.volunteer = user_model.objects.create_user(
            username="volunteer_main",
            email="volunteer_main@example.com",
            password="Volunteer@12345",
            role="volunteer",
            phone="9800000001",
        )

        UserProfile.objects.create(user=self.donor, verification_status="pending")
        UserProfile.objects.create(user=self.volunteer, verification_status="pending")
        UserProfile.objects.create(user=self.ngo, verification_status="verified")

    def _as(self, user):
        self.client.force_authenticate(user=user)

    def _create_request_offer_and_pending_task(self):
        self._as(self.ngo)
        request_payload = {
            "title": "Need Winter Jackets",
            "description": "For families in need",
            "category": "clothes",
            "quantity_needed": 10,
            "urgency": "High",
            "location": "Kathmandu",
        }
        req_res = self.client.post("/api/requests/", request_payload, format="json")
        self.assertEqual(req_res.status_code, status.HTTP_201_CREATED)
        request_id = req_res.data["id"]

        self._as(self.donor)
        offer_payload = {
            "donation_request": request_id,
            "type": "material",
            "quantity": 2,
            "message": "I can help with jackets",
            "fulfillment_type": "volunteer_pickup",
            "pickup_location": "Baneshwor",
        }
        offer_res = self.client.post("/api/donations/offers/", offer_payload, format="json")
        self.assertEqual(offer_res.status_code, status.HTTP_201_CREATED)
        offer_id = offer_res.data["id"]

        self._as(self.ngo)
        accept_res = self.client.patch(
            f"/api/donations/offers/{offer_id}/accept-reject/",
            {"status": "accepted"},
            format="json",
        )
        self.assertEqual(accept_res.status_code, status.HTTP_200_OK)

        task = VolunteerTask.objects.get(donation_offer_id=offer_id)
        return request_id, offer_id, task.id

    def test_login_returns_access_and_refresh_tokens(self):
        payload = {"username": "donor_main", "password": "Donor@12345"}
        response = self.client.post("/api/auth/login/", payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_donation_offer_acceptance_creates_pending_volunteer_task(self):
        request_id, offer_id, task_id = self._create_request_offer_and_pending_task()

        donation_request = DonationRequest.objects.get(pk=request_id)
        offer = DonationOffer.objects.get(pk=offer_id)
        task = VolunteerTask.objects.get(pk=task_id)

        self.assertEqual(offer.status, "accepted")
        self.assertEqual(donation_request.status, "matched")
        self.assertEqual(task.task_status, "pending_volunteer")
        self.assertIsNone(task.volunteer)

    def test_volunteer_can_claim_pending_task(self):
        _, _, task_id = self._create_request_offer_and_pending_task()

        self._as(self.volunteer)
        claim_res = self.client.post(f"/api/volunteers/tasks/{task_id}/claim/", format="json")
        self.assertEqual(claim_res.status_code, status.HTTP_200_OK)

        task = VolunteerTask.objects.get(pk=task_id)
        self.assertEqual(task.task_status, "assigned")
        self.assertEqual(task.volunteer_id, self.volunteer.id)

    def test_chat_room_send_and_read_messages(self):
        self._as(self.donor)
        room_res = self.client.post(
            "/api/chat/room/",
            {"other_user_id": self.ngo.id},
            format="json",
        )
        self.assertIn(room_res.status_code, (status.HTTP_200_OK, status.HTTP_201_CREATED))
        room_id = room_res.data["id"]

        send_res = self.client.post(
            "/api/chat/send/",
            {"room_id": room_id, "text": "Hello NGO"},
            format="json",
        )
        self.assertEqual(send_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(send_res.data["text"], "Hello NGO")

        list_res = self.client.get(f"/api/chat/messages/{room_id}/")
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        self.assertTrue(any(msg["text"] == "Hello NGO" for msg in list_res.data))

        mark_read_res = self.client.post("/api/chat/read/", {"room_id": room_id}, format="json")
        self.assertEqual(mark_read_res.status_code, status.HTTP_200_OK)

    def test_notifications_register_device_and_mark_read(self):
        Notification.objects.create(
            user=self.donor,
            notification_type="system",
            title="Welcome",
            message="Welcome to ShareCare",
            is_read=False,
        )

        self._as(self.donor)
        register_res = self.client.post(
            "/api/notifications/register-device/",
            {"token": "sample_fcm_token_1234567890"},
            format="json",
        )
        self.assertEqual(register_res.status_code, status.HTTP_200_OK)
        self.assertTrue(DeviceToken.objects.filter(user=self.donor).exists())

        mark_res = self.client.post("/api/notifications/mark-read/", format="json")
        self.assertEqual(mark_res.status_code, status.HTTP_200_OK)
        self.assertFalse(Notification.objects.filter(user=self.donor, is_read=False).exists())

    def test_support_ticket_create_and_list(self):
        self._as(self.donor)
        create_res = self.client.post(
            "/api/support/tickets/",
            {
                "subject": "Help needed",
                "message": "I need help with donation flow",
                "category": "other",
            },
            format="json",
        )
        self.assertEqual(create_res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(SupportTicket.objects.filter(user=self.donor).count(), 1)

        list_res = self.client.get("/api/support/tickets/my/")
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(list_res.data), 1)
