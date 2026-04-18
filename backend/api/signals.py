"""Signal handlers to automatically create notifications for important events."""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import DonationOffer, DonationRequest, Notification, VolunteerTask


@receiver(post_save, sender=DonationRequest)
def notify_on_donation_created(sender, instance, created, **kwargs):
    """Create a notification when a new donation request is created."""
    if created:
        Notification.objects.create(
            user=instance.created_by,
            notification_type='donation_available',
            title=f'Request Created: {instance.title}',
            message=f'Your donation request "{instance.title}" has been posted and is available to donors and volunteers.',
            donation_request=instance,
        )


@receiver(post_save, sender=DonationOffer)
def notify_on_donation_offer(sender, instance, created, update_fields, **kwargs):
    """Create notifications when donation offers are made or status changes."""
    if created:
        Notification.objects.create(
            user=instance.donation_request.created_by,
            notification_type='offer_received',
            title=f'New Offer for: {instance.donation_request.title}',
            message=f'{instance.donor.get_full_name() or instance.donor.username} has offered {instance.quantity} of {instance.get_type_display()} for your request.',
            donation_request=instance.donation_request,
            donation_offer=instance,
        )
    elif update_fields and 'status' in update_fields and instance.status == 'accepted':
        Notification.objects.create(
            user=instance.donor,
            notification_type='offer_accepted',
            title=f'Offer Accepted: {instance.donation_request.title}',
            message=f'Your donation offer has been accepted! A volunteer will pick it up soon.',
            donation_request=instance.donation_request,
            donation_offer=instance,
        )


@receiver(post_save, sender=VolunteerTask)
def notify_on_volunteer_task(sender, instance, created, update_fields, **kwargs):
    """Create notifications when volunteer tasks are created or status changes."""
    if created:
        Notification.objects.create(
            user=instance.volunteer,
            notification_type='task_assigned',
            title='New Volunteer Task',
            message=f'A new task has been assigned to you for: {instance.donation_request.title}. Pickup from: {instance.pickup_location}',
            donation_request=instance.donation_request,
            volunteer_task=instance,
        )
        
        Notification.objects.create(
            user=instance.donation_request.created_by,
            notification_type='offer_accepted',
            title=f'Volunteer Accepted: {instance.donation_request.title}',
            message=f'{instance.volunteer.get_full_name() or instance.volunteer.username} has accepted to handle your donation request.',
            donation_request=instance.donation_request,
            volunteer_task=instance,
        )
    elif update_fields and 'task_status' in update_fields:
        if instance.task_status == 'picked':
            Notification.objects.create(
                user=instance.donation_request.created_by,
                notification_type='donation_picked',
                title=f'Donation Picked Up: {instance.donation_request.title}',
                message=f'{instance.volunteer.get_full_name() or instance.volunteer.username} has picked up your donation.',
                donation_request=instance.donation_request,
                volunteer_task=instance,
            )
        elif instance.task_status == 'delivered':
            Notification.objects.create(
                user=instance.donation_request.created_by,
                notification_type='donation_delivered',
                title=f'Donation Delivered: {instance.donation_request.title}',
                message=f'Your donation has been successfully delivered to {instance.delivery_location}.',
                donation_request=instance.donation_request,
                volunteer_task=instance,
            )
