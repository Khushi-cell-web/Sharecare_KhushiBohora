"""Create volunteer tasks for material pickup / delivery."""
from apps.volunteers.models import VolunteerTask


def create_pending_volunteer_task_for_offer(offer):
    """After NGO accepts a material offer with volunteer pickup, queue a claimable task."""
    if offer.type != 'material' or offer.fulfillment_type != 'volunteer_pickup':
        return None
    if VolunteerTask.objects.filter(donation_offer=offer).exists():
        return None
    dr = offer.donation_request
    pickup_src = (offer.pickup_location or dr.location or '').strip()
    delivery_src = (dr.location or pickup_src or '').strip()
    pickup = pickup_src[:255] if pickup_src else '—'
    delivery = delivery_src[:255] if delivery_src else '—'
    return VolunteerTask.objects.create(
        volunteer=None,
        donation_request=dr,
        donation_offer=offer,
        pickup_location=pickup,
        delivery_location=delivery,
        pickup_latitude=offer.pickup_latitude,
        pickup_longitude=offer.pickup_longitude,
        delivery_latitude=dr.latitude,
        delivery_longitude=dr.longitude,
        task_status='pending_volunteer',
    )


def create_volunteer_task_for_donation_if_needed(donation):
    """
    Donation record + material + volunteer_pickup → pending task.
    Standalone: donation_request null (task links donation only — use donation_request from constraint:
    we need at least one of donation_request or donation; standalone uses donation FK only).
    """
    from .models import Donation

    if not isinstance(donation, Donation):
        return None
    if donation.donation_type != 'material' or donation.fulfillment_type != 'volunteer_pickup':
        return None
    if VolunteerTask.objects.filter(donation=donation).exists():
        return None

    dr = donation.donation_request
    if dr:
        pickup = (donation.pickup_location or dr.location or '—')[:255]
        delivery = (dr.location or pickup or '—')[:255]
        return VolunteerTask.objects.create(
            volunteer=None,
            donation_request=dr,
            donation=donation,
            donation_offer=None,
            pickup_location=pickup,
            delivery_location=delivery,
            pickup_latitude=donation.pickup_latitude,
            pickup_longitude=donation.pickup_longitude,
            delivery_latitude=dr.latitude,
            delivery_longitude=dr.longitude,
            task_status='pending_volunteer',
        )

    pickup = (donation.pickup_location or '—')[:255]
    delivery = (donation.delivery_location or '—')[:255]
    return VolunteerTask.objects.create(
        volunteer=None,
        donation_request=None,
        donation=donation,
        donation_offer=None,
        pickup_location=pickup,
        delivery_location=delivery,
        pickup_latitude=donation.pickup_latitude,
        pickup_longitude=donation.pickup_longitude,
        delivery_latitude=donation.delivery_latitude,
        delivery_longitude=donation.delivery_longitude,
        task_status='pending_volunteer',
    )
