"""Blood donation 90-day cooldown validation and recording."""
from __future__ import annotations

from datetime import timedelta
from typing import Optional, Tuple

from django.utils import timezone

from .models import BloodDonationRecord

BLOOD_COOLDOWN_DAYS = 90
BLOOD_COOLDOWN_MESSAGE = (
    'You can donate blood only after 3 months from your last donation'
)


def can_user_donate_blood(user) -> Tuple[bool, Optional[str]]:
    """Return (allowed, error_message). error_message set when not allowed."""
    if not user or not user.is_authenticated:
        return False, 'Authentication required.'
    last = (
        BloodDonationRecord.objects.filter(user=user)
        .order_by('-recorded_at')
        .first()
    )
    if not last:
        return True, None
    delta = timezone.now() - last.recorded_at
    if delta < timedelta(days=BLOOD_COOLDOWN_DAYS):
        return False, BLOOD_COOLDOWN_MESSAGE
    return True, None


def record_blood_donation(user, source: str = '') -> None:
    """Append a blood donation event for cooldown tracking."""
    if user is None:
        return
    now = timezone.now()
    # Avoid duplicate rows when multiple signals fire for the same event.
    if BloodDonationRecord.objects.filter(
        user=user,
        recorded_at__gte=now - timedelta(seconds=20),
    ).exists():
        return
    BloodDonationRecord.objects.create(
        user=user,
        source=(source or '')[:48],
    )
