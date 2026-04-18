"""
Admin panel app: Reports, user suspension, system monitoring.
"""
from django.conf import settings
from django.db import models


class Report(models.Model):
    """User-generated report (e.g. abuse, spam)."""
    REPORT_TYPE_CHOICES = [
        ('abuse', 'Abuse'),
        ('spam', 'Spam'),
        ('fraud', 'Fraud'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('reviewed', 'Reviewed'),
        ('resolved', 'Resolved'),
    ]
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports_submitted',
    )
    reported_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports_against',
        null=True,
        blank=True,
    )
    report_type = models.CharField(max_length=20, choices=REPORT_TYPE_CHOICES)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'adminpanel_report'
        ordering = ['-created_at']

    def __str__(self):
        return f"Report #{self.pk} - {self.get_report_type_display()}"


class UserSuspension(models.Model):
    """Admin suspension of a user account."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='suspensions',
    )
    reason = models.TextField()
    suspended_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='suspensions_issued',
    )
    suspended_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)  # None = indefinite
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'adminpanel_usersuspension'
        ordering = ['-suspended_at']

    def __str__(self):
        return f"Suspension: {self.user.username}"


class ActivityLog(models.Model):
    """High-level admin/system activity log for monitoring."""

    ACTION_CHOICES = [
        ('verification_update', 'Verification updated'),
        ('user_suspended', 'User suspended'),
        ('user_unsuspended', 'User unsuspended'),
        ('report_updated', 'Report updated'),
        ('system', 'System'),
    ]

    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activity_logs',
    )
    action = models.CharField(max_length=40, choices=ACTION_CHOICES)
    message = models.TextField()
    target_type = models.CharField(max_length=50, blank=True)
    target_id = models.PositiveIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'adminpanel_activitylog'
        ordering = ['-created_at']

    def __str__(self):
        who = self.actor.username if self.actor else 'system'
        return f"{who}: {self.get_action_display()}"
