"""
FCM (Firebase Cloud Messaging) service for push notifications.
"""
import os
from typing import Optional

from django.conf import settings


def _get_firebase_credentials() -> Optional[str]:
    """Path to Firebase service account JSON."""
    return os.getenv('FIREBASE_CREDENTIALS') or getattr(settings, 'FIREBASE_CREDENTIALS', None)


def send_fcm_to_user(user, title: str, body: str, data: Optional[dict] = None) -> int:
    """
    Send FCM to all device tokens for a user. Returns count of successful sends.
    """
    from .models import DeviceToken

    tokens = list(DeviceToken.objects.filter(user=user).values_list('token', flat=True))
    if not tokens:
        return 0

    creds_path = _get_firebase_credentials()
    if not creds_path or not os.path.exists(creds_path):
        return 0

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred = credentials.Certificate(creds_path)
            firebase_admin.initialize_app(cred)

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            tokens=tokens,
        )
        response = messaging.send_multicast(message)
        return response.success_count
    except Exception:
        return 0
