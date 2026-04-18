"""
Donation matchmaking service.

Creates `DonationMatch` records automatically when:
- a standalone `Donation` is created (donor -> nearby open `DonationRequest`)
- a `DonationRequest` is created (request -> nearby pending `Donation` candidates)
- a `DonationOffer` is created (donor -> request: match exists, donor side is considered accepted)

When both donor and receiver accept a match, we convert it into an accepted
`DonationOffer` so the existing donation lifecycle continues unchanged.
"""

from __future__ import annotations

import math
from typing import Optional, Tuple

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.notifications.signals import notify

from .models import Donation, DonationMatch, DonationOffer, DonationRequest
from .delivery_service import create_pending_volunteer_task_for_offer


RADIUS_DEFAULT_KM = 20.0
MAX_MATCHES_PER_MATCHING = 10


def _coords(lat: Optional[float], lng: Optional[float]) -> Optional[Tuple[float, float]]:
    if lat is None or lng is None:
        return None
    try:
        lat_f = float(lat)
        lng_f = float(lng)
    except (TypeError, ValueError):
        return None
    return lat_f, lng_f


def _haversine_km(a_lat: float, a_lng: float, b_lat: float, b_lng: float) -> float:
    """Great-circle distance in km."""
    r = 6371.0
    d_lat = math.radians(b_lat - a_lat)
    d_lng = math.radians(b_lng - a_lng)
    a1 = math.sin(d_lat / 2) ** 2
    a2 = math.cos(math.radians(a_lat)) * math.cos(math.radians(b_lat)) * math.sin(d_lng / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a1 + a2), math.sqrt(1 - (a1 + a2)))
    return r * c


def _donation_source_coords(donation: Donation) -> Optional[Tuple[float, float]]:
    # Prefer pickup coordinates for material volunteer delivery.
    return (
        _coords(donation.pickup_latitude, donation.pickup_longitude)
        or _coords(donation.delivery_latitude, donation.delivery_longitude)
    )


def _distance_between_donation_and_request(donation: Donation, req: DonationRequest) -> Optional[float]:
    a = _donation_source_coords(donation)
    b = _coords(req.latitude, req.longitude)
    if not a or not b:
        return None
    return _haversine_km(a[0], a[1], b[0], b[1])


def _notify_match_found(match: DonationMatch) -> None:
    # Spec-required message
    base_message = 'A match has been found for your donation/request'
    details = f" Category: {match.donation_request.category}, Location: {match.donation_request.location}."

    try:
        notify(
            match.donor,
            'match_found',
            'Match Found',
            base_message + details,
            target_id=match.donation_request_id,
            target_type='donation_request',
        )
        notify(
            match.receiver,
            'match_found',
            'Match Found',
            base_message + details,
            target_id=match.donation_request_id,
            target_type='donation_request',
        )
    except Exception:
        # Notifications are best-effort
        pass


@transaction.atomic
def create_matches_for_donation(donation: Donation, radius_km: float = RADIUS_DEFAULT_KM) -> int:
    """
    Create DonationMatch rows for a standalone Donation (donation_request is null)
    against open DonationRequests with same category and nearby coordinates.
    """
    if donation.donation_request_id is not None:
        return 0
    Donation.expire_due_donations()
    if donation.status not in ('pending', 'confirmed'):
        return 0
    if not donation.category:
        return 0
    if donation.category == 'food' and donation.is_expired:
        return 0

    reqs = DonationRequest.objects.filter(
        status='open',
        category=donation.category,
    ).select_related('created_by')

    created = 0
    for req in reqs:
        dist = _distance_between_donation_and_request(donation, req)
        if dist is None or dist > radius_km:
            continue

        # Avoid duplicates (donation + request pair)
        exists = DonationMatch.objects.filter(
            donation=donation,
            donation_request=req,
        ).exists()
        if exists:
            continue

        match = DonationMatch.objects.create(
            donor=donation.donor,
            receiver=req.created_by,
            donation=donation,
            donation_request=req,
            distance_km=dist,
            donor_decision='pending',
            receiver_decision='pending',
            status='pending',
        )
        created += 1
        _notify_match_found(match)
        if created >= MAX_MATCHES_PER_MATCHING:
            break

    return created


@transaction.atomic
def create_matches_for_request(request: DonationRequest, radius_km: float = RADIUS_DEFAULT_KM) -> int:
    """Create DonationMatch rows for an open request against nearby standalone Donations."""
    Donation.expire_due_donations()
    if request.status != 'open':
        return 0

    now = timezone.now()

    donations = Donation.objects.filter(
        status__in=('pending', 'confirmed'),
        donation_request__isnull=True,
        category=request.category,
    ).filter(
        ~Q(category='food')
        | Q(category='food', valid_until__gt=now)
        | Q(category='food', valid_until__isnull=True, expiry_date__gt=now)
    ).select_related('donor')

    created = 0
    for donation in donations:
        dist = _distance_between_donation_and_request(donation, request)
        if dist is None or dist > radius_km:
            continue

        exists = DonationMatch.objects.filter(
            donation=donation,
            donation_request=request,
        ).exists()
        if exists:
            continue

        match = DonationMatch.objects.create(
            donor=donation.donor,
            receiver=request.created_by,
            donation=donation,
            donation_request=request,
            distance_km=dist,
            donor_decision='pending',
            receiver_decision='pending',
            status='pending',
        )
        created += 1
        _notify_match_found(match)
        if created >= MAX_MATCHES_PER_MATCHING:
            break

    return created


@transaction.atomic
def create_match_for_offer(offer: DonationOffer) -> Optional[DonationMatch]:
    """
    When a DonationOffer is created, we also create a DonationMatch record to
    drive the new UI flow.
    """
    if offer.status not in ('pending',):
        return None

    exists = DonationMatch.objects.filter(
        donation_offer=offer,
        donation_request=offer.donation_request,
    ).exists()
    if exists:
        return None

    # Best-effort distance for UI
    dist = None
    try:
        req_coords = _coords(offer.donation_request.latitude, offer.donation_request.longitude)
        offer_coords = _coords(offer.pickup_latitude, offer.pickup_longitude)
        if req_coords and offer_coords:
            dist = _haversine_km(offer_coords[0], offer_coords[1], req_coords[0], req_coords[1])
    except Exception:
        dist = None

    match = DonationMatch.objects.create(
        donor=offer.donor,
        receiver=offer.donation_request.created_by,
        donation=None,
        donation_request=offer.donation_request,
        donation_offer=offer,
        distance_km=dist,
        donor_decision='accepted',  # donor implicitly accepted by creating an offer
        receiver_decision='pending',
        status='pending',
    )
    _notify_match_found(match)
    return match


@transaction.atomic
def finalize_match_if_both_accepted(match: DonationMatch) -> None:
    """Convert match into an accepted DonationOffer when both sides accept."""
    if match.status != 'accepted':
        return
    if match.donor_decision != 'accepted' or match.receiver_decision != 'accepted':
        return

    dr = match.donation_request

    # Create or update the donation offer
    offer = match.donation_offer
    if offer is None:
        if match.donation is None:
            return
        donation = match.donation

        offer, _ = DonationOffer.objects.get_or_create(
            donor=match.donor,
            donation_request=dr,
            defaults=dict(
                type=donation.donation_type,
                quantity=donation.quantity,
                message=donation.description or '',
                status='accepted',
                fulfillment_type=donation.fulfillment_type,
                pickup_location=donation.pickup_location,
                pickup_latitude=donation.pickup_latitude,
                pickup_longitude=donation.pickup_longitude,
            ),
        )

        # Keep fields in sync for repeat-safe runs.
        offer.type = donation.donation_type
        offer.quantity = donation.quantity
        offer.message = donation.description or ''
        offer.status = 'accepted'
        offer.fulfillment_type = donation.fulfillment_type
        offer.pickup_location = donation.pickup_location
        offer.pickup_latitude = donation.pickup_latitude
        offer.pickup_longitude = donation.pickup_longitude
        offer.save()

        match.donation_offer = offer

    if offer.status != 'accepted':
        offer.status = 'accepted'
        offer.save(update_fields=['status'])

    # Mark donation lifecycle state
    dr.status = 'matched'
    dr.save(update_fields=['status', 'updated_at'])

    create_pending_volunteer_task_for_offer(offer)

    if match.donation is not None and match.donation.status != 'confirmed':
        match.donation.status = 'confirmed'
        match.donation.save(update_fields=['status', 'updated_at'])

    # Fulfillment check
    from django.db.models import Sum

    total_accepted = DonationOffer.objects.filter(
        donation_request=dr,
        status='accepted',
    ).aggregate(total=Sum('quantity'))['total'] or 0

    if total_accepted >= dr.quantity_needed and dr.status != 'fulfilled':
        dr.status = 'fulfilled'
        dr.save(update_fields=['status', 'updated_at'])
        try:
            from .views import _send_request_fulfilled_email

            _send_request_fulfilled_email(dr)
        except Exception:
            pass

    match.save(update_fields=['donation_offer', 'updated_at'])

