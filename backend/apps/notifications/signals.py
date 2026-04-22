"""
Auto notification triggers: create in-app, email, and FCM push on key events.
"""
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings

from apps.donations.models import Donation, DonationOffer, DonationRequest
from apps.users.models import User
from apps.volunteers.models import VolunteerTask

from .models import Notification
from .fcm_service import send_fcm_to_user


def notify(user, notification_type, title, message, target_id=None, target_type=None):
    """Create in-app notification, send FCM push, and send email."""
    if not user:
        return

    valid_types = {choice[0] for choice in Notification.TYPE_CHOICES}
    safe_type = notification_type if notification_type in valid_types else 'system'
    try:
        Notification.objects.create(
            user=user,
            notification_type=safe_type,
            title=title,
            message=message,
            target_id=target_id,
            target_type=target_type or '',
        )
    except Exception:
        # Notification persistence should not block core API workflows.
        pass
    try:
        send_fcm_to_user(
            user, title, message,
            data={
                'type': safe_type,
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


def _notify_volunteers_in_app_only(task_id):
    """Create lightweight in-app alerts for volunteers without blocking on email/FCM."""
    volunteers = list(User.objects.filter(role='volunteer', is_active=True).only('id'))
    if not volunteers:
        return
    rows = [
        Notification(
            user_id=vol.id,
            notification_type='system',
            title='New delivery task',
            message='A new volunteer pickup task is available. Open Pending pickups to claim.',
            target_id=task_id,
            target_type='volunteer_task',
        )
        for vol in volunteers
    ]
    try:
        Notification.objects.bulk_create(rows, batch_size=500)
    except Exception:
        pass


def _task_stakeholders(instance):
    donor = None
    ngo = None
    if instance.donation_id and instance.donation:
        donor = instance.donation.donor
        ngo = instance.donation.accepted_by_ngo
    elif instance.donation_offer_id and instance.donation_offer:
        donor = instance.donation_offer.donor
        ngo = instance.donation_request.created_by if instance.donation_request_id else None
    elif instance.donation_request_id and instance.donation_request:
        donor = None
        ngo = instance.donation_request.created_by
    return donor, ngo


@receiver(pre_save, sender=VolunteerTask)
def on_volunteer_task_pre_save(sender, instance, **kwargs):
    if not instance.pk:
        instance._previous_task_status = None
        instance._previous_volunteer_id = None
        return

    previous = VolunteerTask.objects.filter(pk=instance.pk).values('task_status', 'volunteer_id').first()
    if previous:
        instance._previous_task_status = previous['task_status']
        instance._previous_volunteer_id = previous['volunteer_id']
    else:
        instance._previous_task_status = None
        instance._previous_volunteer_id = None


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


@receiver(post_save, sender=Donation)
def on_donation_created(sender, instance, created, **kwargs):
    if not created:
        return

    ngo_users = list(User.objects.filter(role='ngo', is_active=True).only('id'))
    if not ngo_users:
        return

    donor_name = instance.donor.get_full_name() or instance.donor.username
    donation_title = (instance.description or '').strip().split('\n')[0][:80] or instance.get_category_display()
    rows = [
        Notification(
            user_id=ngo.id,
            notification_type='donation_created',
            title='New donation available',
            message=f'{donor_name} submitted {donation_title}. Open the NGO dashboard to accept it.',
            target_id=instance.pk,
            target_type='donation',
        )
        for ngo in ngo_users
    ]
    try:
        Notification.objects.bulk_create(rows, batch_size=500)
    except Exception:
        pass


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
    previous_status = getattr(instance, '_previous_task_status', None)

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
            donor, ngo = _task_stakeholders(instance)
            ngo_msg = (
                f'A pickup task for "{instance.donation_request.title}" is waiting for a volunteer to claim.'
                if instance.donation_request_id
                else (
                    f'A standalone pickup task is waiting for a volunteer to claim '
                    f'(drop-off: {instance.delivery_location[:80]}).'
                )
            )
            if ngo:
                notify(
                    ngo,
                    'donation_assigned',
                    'Volunteer pickup queued',
                    ngo_msg,
                    target_id=instance.pk,
                    target_type='volunteer_task',
                )
            _notify_volunteers_in_app_only(instance.pk)
    else:
        donor, ngo = _task_stakeholders(instance)
        status_changed = previous_status != instance.task_status

        if instance.volunteer_id and (status_changed or instance._previous_volunteer_id is None):
            notify(
                instance.volunteer,
                'task_status_updated',
                'Task status updated',
                f'Task for "{_volunteer_task_title(instance)}" is now {instance.get_task_status_display()}.',
                target_id=instance.pk,
                target_type='volunteer_task',
            )
        if not status_changed:
            return

        if instance.task_status in ('assigned', 'picked', 'in_transit', 'delivered'):
            if instance.task_status == 'assigned':
                title = 'Volunteer assigned'
                body = f'Your donation for "{_volunteer_task_title(instance)}" has a volunteer assigned.'
                notification_type = 'donation_assigned'
            elif instance.task_status == 'picked':
                title = 'Donation picked up'
                body = f'Volunteer picked up "{_volunteer_task_title(instance)}".'
                notification_type = 'donation_picked_up'
            elif instance.task_status == 'in_transit':
                title = 'Donation in transit'
                body = f'Volunteer is on the way with "{_volunteer_task_title(instance)}".'
                notification_type = 'donation_in_transit'
            else:
                title = 'Donation delivered'
                body = f'Volunteer delivered "{_volunteer_task_title(instance)}".'
                notification_type = 'donation_delivered'

            if donor:
                notify(
                    donor,
                    notification_type,
                    title,
                    body,
                    target_id=instance.pk,
                    target_type='volunteer_task',
                )
            if ngo:
                notify(
                    ngo,
                    notification_type,
                    title,
                    body,
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
            elif instance.donation_id and donor:
                notify(
                    donor,
                    'request_completed',
                    'Delivery completed',
                    'Your standalone donation was delivered by a volunteer.',
                    target_id=instance.pk,
                    target_type='volunteer_task',
                )
