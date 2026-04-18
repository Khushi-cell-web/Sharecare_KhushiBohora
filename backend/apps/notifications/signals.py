"""
Auto notification triggers: create in-app, email, and FCM push on key events.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings

from apps.donations.models import DonationOffer, DonationRequest
from apps.users.models import User
from apps.volunteers.models import VolunteerTask

from .models import Notification
from .fcm_service import send_fcm_to_user


def notify(user, notification_type, title, message, target_id=None, target_type=None):
    """Create in-app notification, send FCM push, and send email."""
    if not user:
        return
        
    Notification.objects.create(
        user=user,
        notification_type=notification_type,
        title=title,
        message=message,
        target_id=target_id,
        target_type=target_type or '',
    )
    try:
        send_fcm_to_user(
            user, title, message,
            data={
                'type': notification_type,
                'target_id': str(target_id or ''),
                'target_type': target_type or '',
            },
        )
    except Exception:
        pass
    _send_email(user, title, message)


def _send_email(user, subject, body):
    """Send email to user if they have an email address and SMTP is configured."""
    email = getattr(user, 'email', None)
    if not email or not str(email).strip() or '@' not in str(email):
        return
    if settings.EMAIL_BACKEND == 'django.core.mail.backends.console.EmailBackend':
        return
    try:
        send_mail(
            subject=f'ShareCare: {subject}',
            message=body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=True,
        )
    except Exception:
        pass


@receiver(post_save, sender=DonationRequest)
def on_donation_request_created(sender, instance, created, **kwargs):
    if created:
        notify(
            instance.created_by,
            'request_created',
            'Request created',
            f'Your request "{instance.title}" has been published.',
            target_id=instance.pk,
            target_type='donation_request',
        )


@receiver(post_save, sender=DonationOffer)
def on_donation_offer_saved(sender, instance, created, **kwargs):
    if created:
        notify(
            instance.donation_request.created_by,
            'offer_received',
            'New donation offer',
            f'A donor offered for "{instance.donation_request.title}".',
            target_id=instance.donation_request_id,
            target_type='donation_request',
        )
        # Confirm submission to donor.
        notify(
            instance.donor,
            'offer_submitted',
            'Offer submitted successfully',
            f'Your offer for "{instance.donation_request.title}" was submitted successfully.',
            target_id=instance.donation_request_id,
            target_type='donation_request',
        )
    else:
        if instance.status == 'accepted':
            if instance.type == 'material' and getattr(instance, 'fulfillment_type', '') == 'self_dropoff':
                offer_msg = (
                    f'Your offer for "{instance.donation_request.title}" was accepted. '
                    'Please arrange to drop off items with the organization.'
                )
            elif instance.type == 'material':
                offer_msg = (
                    f'Your offer for "{instance.donation_request.title}" was accepted. '
                    'A volunteer can claim pickup from your listed pickup location.'
                )
            else:
                offer_msg = f'Your offer for "{instance.donation_request.title}" was accepted.'
            notify(
                instance.donor,
                'offer_accepted',
                'Offer accepted',
                offer_msg,
                target_id=instance.donation_request_id,
                target_type='donation_request',
            )
        elif instance.status == 'rejected':
            notify(
                instance.donor,
                'offer_rejected',
                'Offer declined',
                f'Your offer for "{instance.donation_request.title}" was declined.',
                target_id=instance.donation_request_id,
                target_type='donation_request',
            )


def _volunteer_task_title(instance):
    if instance.donation_request_id:
        return instance.donation_request.title
    if instance.donation_id:
        return (instance.donation.description or '').strip().split('\n')[0][:80] or instance.donation.get_category_display()
    return 'Task'


@receiver(post_save, sender=VolunteerTask)
def on_volunteer_task_saved(sender, instance, created, **kwargs):
    if created:
        if instance.volunteer_id:
            notify(
                instance.volunteer,
                'task_assigned',
                'New task assigned',
                f'You have been assigned a task for "{_volunteer_task_title(instance)}".',
                target_id=instance.pk,
                target_type='volunteer_task',
            )
        else:
            ngo_msg = (
                f'A pickup task for "{instance.donation_request.title}" is waiting for a volunteer to claim.'
                if instance.donation_request_id
                else (
                    f'A standalone pickup task is waiting for a volunteer to claim '
                    f'(drop-off: {instance.delivery_location[:80]}).'
                )
            )
            if instance.donation_request_id:
                notify(
                    instance.donation_request.created_by,
                    'request_matched',
                    'Volunteer pickup queued',
                    ngo_msg,
                    target_id=instance.donation_request_id,
                    target_type='donation_request',
                )
            for vol in User.objects.filter(role='volunteer', is_active=True):
                notify(
                    vol,
                    'system',
                    'New delivery task',
                    'A new volunteer pickup task is available. Open Pending pickups to claim.',
                    target_id=instance.pk,
                    target_type='volunteer_task',
                )
    else:
        if instance.volunteer_id:
            notify(
                instance.volunteer,
                'task_status_updated',
                'Task status updated',
                f'Task for "{_volunteer_task_title(instance)}" is now {instance.get_task_status_display()}.',
                target_id=instance.pk,
                target_type='volunteer_task',
            )
        if instance.task_status == 'delivered':
            if instance.donation_request_id:
                notify(
                    instance.donation_request.created_by,
                    'request_completed',
                    'Delivery completed',
                    f'Volunteer has delivered for "{instance.donation_request.title}".',
                    target_id=instance.donation_request_id,
                    target_type='donation_request',
                )
            elif instance.donation_id:
                notify(
                    instance.donation.donor,
                    'request_completed',
                    'Delivery completed',
                    'Your standalone donation was delivered by a volunteer.',
                    target_id=instance.pk,
                    target_type='volunteer_task',
                )
