"""Callable notification helpers for events not covered by signals."""
from .signals import notify


def notify_donation_made(donation_request, donor, amount):
    """Notify NGO when a monetary donation is made."""
    notify(
        donation_request.created_by,
        'donation_made',
        'New Donation Received',
        f'{donor.username} donated {amount} to "{donation_request.title}".',
        target_id=donation_request.id,
        target_type='donation_request',
    )


def notify_campaign_created(donation_request):
    notify(
        donation_request.created_by,
        'campaign_created',
        'Campaign Created',
        f'Your campaign "{donation_request.title}" has been created.',
        target_id=donation_request.id,
        target_type='donation_request',
    )


def notify_campaign_approved(donation_request):
    notify(
        donation_request.created_by,
        'campaign_approved',
        'Campaign Approved',
        f'Your campaign "{donation_request.title}" has been approved.',
        target_id=donation_request.id,
        target_type='donation_request',
    )


def notify_campaign_goal_reached(donation_request):
    notify(
        donation_request.created_by,
        'campaign_goal_reached',
        'Campaign Goal Reached!',
        f'Your campaign "{donation_request.title}" has reached its fundraising goal!',
        target_id=donation_request.id,
        target_type='donation_request',
    )


def notify_verification_updated(user, new_status, notes=''):
    """Notify an NGO user when their verification status changes."""
    msg = f'Your organization verification status has been updated to "{new_status}".'
    if notes:
        msg += f' Notes: {notes}'
    notify(
        user,
        'verification_updated',
        'Verification Status Updated',
        msg,
    )


def notify_payment_received(donation_request, donor, amount, currency='NPR'):
    """Notify NGO when payment is confirmed."""
    notify(
        donation_request.created_by,
        'donation_made',
        'Payment Received',
        f'{donor.username} paid {currency} {amount} for "{donation_request.title}".',
        target_id=donation_request.id,
        target_type='donation_request',
    )
