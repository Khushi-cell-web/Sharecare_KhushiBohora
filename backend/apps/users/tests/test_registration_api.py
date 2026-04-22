from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import UserProfile


class RegisterApiTests(APITestCase):
    register_url = "/api/auth/register/"

    def test_register_customer_success(self):
        payload = {
            "username": "customer_001",
            "email": "customer001@example.com",
            "password": "Customer@123",
            "password_confirm": "Customer@123",
            "first_name": "Test",
            "last_name": "Customer",
            "role": "donor",
            "phone": "9800000000",
        }

        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["username"], payload["username"])
        self.assertEqual(response.data["email"], payload["email"])
        self.assertEqual(response.data["role"], "donor")
        self.assertNotIn("password", response.data)

        user = get_user_model().objects.get(email=payload["email"])
        self.assertTrue(user.check_password(payload["password"]))

        profile = UserProfile.objects.get(user=user)
        self.assertEqual(profile.verification_status, "pending")

    def test_register_rejects_duplicate_email(self):
        user_model = get_user_model()
        user_model.objects.create_user(
            username="existing_user",
            email="existing@example.com",
            password="Existing@123",
            role="donor",
        )

        payload = {
            "username": "new_user",
            "email": "existing@example.com",
            "password": "Customer@123",
            "password_confirm": "Customer@123",
            "role": "donor",
        }

        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data)

    def test_register_rejects_password_mismatch(self):
        payload = {
            "username": "customer_002",
            "email": "customer002@example.com",
            "password": "Customer@123",
            "password_confirm": "Different@123",
            "role": "donor",
        }

        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password_confirm", response.data)

    def test_register_ngo_requires_org_and_name_fields(self):
        payload = {
            "username": "ngo_001",
            "email": "ngo001@example.com",
            "password": "NgoStrong@123",
            "password_confirm": "NgoStrong@123",
            "role": "ngo",
            "organization": "",
            "first_name": "",
            "last_name": "",
        }

        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("organization", response.data)

    def test_register_volunteer_requires_phone(self):
        payload = {
            "username": "volunteer_001",
            "email": "volunteer001@example.com",
            "password": "Volunteer@123",
            "password_confirm": "Volunteer@123",
            "role": "volunteer",
            "phone": "",
        }

        response = self.client.post(self.register_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone", response.data)
