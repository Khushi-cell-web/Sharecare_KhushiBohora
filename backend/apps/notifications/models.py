"""
Notifications app: Notification model, DeviceToken for FCM, auto-trigger via Django signals.
"""
from django.conf import settings
from django.db import models


class DeviceToken(models.Model):
    """FCM device token for push notifications."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='device_tokens',
    )
    token = models.CharField(max_length=512)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications_devicetoken'
        unique_together = [['user', 'token']]
        ordering = ['-created_at']


class Notification(models.Model):
    """In-app notification for a user."""
    TYPE_CHOICES = [
        ('request_created', 'Request Created'),
        ('offer_received', 'Offer Received'),
        ('offer_submitted', 'Offer Submitted'),
        ('offer_accepted', 'Offer Accepted'),
        ('offer_rejected', 'Offer Rejected'),
        ('donation_created', 'Donation Created'),
        ('donation_accepted', 'Donation Accepted'),
        ('donation_assigned', 'Donation Assigned'),
        ('donation_picked_up', 'Donation Picked Up'),
        ('donation_in_transit', 'Donation In Transit'),
        ('donation_delivered', 'Donation Delivered'),
        ('task_assigned', 'Task Assigned'),
        ('task_status_updated', 'Task Status Updated'),
        ('request_matched', 'Request Matched'),
        ('request_completed', 'Request Completed'),
        ('verification_updated', 'Verification Updated'),
        ('donation_made', 'Donation Made'),
        ('campaign_created', 'Campaign Created'),
        ('campaign_approved', 'Campaign Approved'),
        ('campaign_goal_reached', 'Campaign Goal Reached'),
        ('match_found', 'Match Found'),
        ('match_accepted', 'Match Accepted'),
        ('match_rejected', 'Match Rejected'),
        ('system', 'System'),
    ]
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    notification_type = models.CharField(max_length=40, choices=TYPE_CHOICES)
    title = models.CharField(max_length=255)
    message = models.TextField()
    # Optional link to related object (e.g. request id, task id)
    target_id = models.PositiveIntegerField(null=True, blank=True)
    target_type = models.CharField(max_length=50, blank=True)  # e.g. 'donation_request', 'volunteer_task'
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications_notification'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username}: {self.title}"
