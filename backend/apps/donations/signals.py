"""Blood donation history recording from payments, offers, deliveries, and standalone donations."""
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.payments.models import DonationTransaction
from apps.volunteers.models import VolunteerTask

from .blood_utils import record_blood_donation
from .models import Donation, DonationOffer, DonationRequest
from .models import DonationMatch

from .matchmaking_service import (
    create_match_for_offer,
    create_matches_for_donation,
    create_matches_for_request,
    finalize_match_if_both_accepted,
)


@receiver(post_save, sender=Donation)
def blood_on_donation_completed(sender, instance, created, **kwargs):
    if not created:
        return
    if instance.category != 'blood' or instance.status != 'completed':
        return
    record_blood_donation(instance.donor, 'standalone_completed')


@receiver(post_save, sender=DonationOffer)
def blood_on_offer_completed(sender, instance, **kwargs):
    if instance.status != 'completed':
        return
    dr = instance.donation_request
    if dr.category != 'blood':
        return
    record_blood_donation(instance.donor, 'offer_completed')


@receiver(post_save, sender=DonationTransaction)
def blood_on_payment_completed(sender, instance, **kwargs):
    if instance.status not in ('completed', 'confirmed'):
        return
    if not instance.donation_request_id:
        return
    dr = instance.donation_request
    if dr.category != 'blood':
        return
    record_blood_donation(instance.user, 'payment')


@receiver(post_save, sender=Donation)
def matchmaking_on_donation_created(sender, instance: Donation, created: bool, **kwargs):
    if not created:
        return
    try:
        create_matches_for_donation(instance)
    except Exception:
        pass


@receiver(post_save, sender=DonationRequest)
def matchmaking_on_request_created(sender, instance: DonationRequest, created: bool, **kwargs):
    if not created:
        return
    try:
        create_matches_for_request(instance)
    except Exception:
        pass


@receiver(post_save, sender=DonationOffer)
def matchmaking_on_offer_saved(sender, instance: DonationOffer, created: bool, **kwargs):
    """
    Keep DonationMatch in sync when DonationOffer is created/accepted/rejected
    through either the new matchmaking UI or the existing NGO accept/reject UI.
    """
    try:
        match = DonationMatch.objects.filter(donation_offer=instance).first()

        if created and match is None:
            create_match_for_offer(instance)
            return

        if not match:
            return

        if instance.status == 'accepted':
            match.receiver_decision = 'accepted'
            if match.donor_decision == 'accepted':
                match.status = 'accepted'
            match.save(update_fields=['receiver_decision', 'status', 'updated_at'])
            finalize_match_if_both_accepted(match)
        elif instance.status == 'rejected':
            match.receiver_decision = 'rejected'
            match.status = 'rejected'
            match.save(update_fields=['receiver_decision', 'status', 'updated_at'])
    except Exception:
        pass


@receiver(post_save, sender=VolunteerTask)
def blood_on_volunteer_delivered(sender, instance, **kwargs):
    if instance.task_status != 'delivered':
        return
    if instance.donation_request_id and instance.donation_request.category == 'blood':
        donor = None
        if instance.donation_offer_id and instance.donation_offer:
            donor = instance.donation_offer.donor
        if donor:
            record_blood_donation(donor, 'volunteer_delivered')
        return
    if instance.donation_id and instance.donation.category == 'blood':
        record_blood_donation(instance.donation.donor, 'volunteer_delivered_standalone')
