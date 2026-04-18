"""
Volunteers app: VolunteerTask, pickup & delivery tracking, task status flow.
pending_volunteer: NGO accepted offer, waiting for a volunteer to claim.
Flow: pending_volunteer -> assigned -> picked -> in_transit -> delivered.
"""
from django.conf import settings
from django.db import models


class VolunteerTask(models.Model):
    """Task for a DonationRequest (pickup/delivery). volunteer=None until claimed."""
    TASK_STATUS_CHOICES = [
        ('pending_volunteer', 'Waiting for volunteer'),
        ('assigned', 'Accepted by Volunteer'),
        ('picked', 'Picked Up'),
        ('in_transit', 'In Transit'),
        ('delivered', 'Delivered'),
    ]
    volunteer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='volunteer_tasks',
        null=True,
        blank=True,
    )
    donation_request = models.ForeignKey(
        'donations.DonationRequest',
        on_delete=models.CASCADE,
        related_name='volunteer_tasks',
        null=True,
        blank=True,
    )
    """Standalone donation pickup/delivery (no campaign). Exactly one of donation_request or donation should be set."""
    donation = models.ForeignKey(
        'donations.Donation',
        on_delete=models.CASCADE,
        related_name='volunteer_tasks',
        null=True,
        blank=True,
    )
    donation_offer = models.ForeignKey(
        'donations.DonationOffer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='volunteer_tasks_for_offer',
    )
    pickup_location = models.CharField(max_length=255)
    delivery_location = models.CharField(max_length=255)
    pickup_latitude = models.FloatField(null=True, blank=True)
    pickup_longitude = models.FloatField(null=True, blank=True)
    delivery_latitude = models.FloatField(null=True, blank=True)
    delivery_longitude = models.FloatField(null=True, blank=True)
    task_status = models.CharField(
        max_length=20,
        choices=TASK_STATUS_CHOICES,
        default='assigned',
    )
    points_awarded = models.BooleanField(default=False)
    points_earned = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_volunteer_task'
        ordering = ['-created_at']
        constraints = [
            models.CheckConstraint(
                condition=models.Q(donation_request__isnull=False)
                | models.Q(donation__isnull=False),
                name='volunteer_task_request_or_standalone_donation',
            ),
        ]

    def __str__(self):
        uname = self.volunteer.get_username() if self.volunteer_id else 'Unassigned'
        return f"Task #{self.pk} - {uname} ({self.task_status})"

    def completion_points(self):
        """Points for this task completion. High urgency requests get bonus points."""
        if self.donation_request_id and self.donation_request and self.donation_request.urgency == 'High':
            return 20
        return 10


class VolunteerTaskDecline(models.Model):
    """Volunteer chose not to see this pending task again."""

    volunteer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='volunteer_task_declines',
    )
    volunteer_task = models.ForeignKey(
        VolunteerTask,
        on_delete=models.CASCADE,
        related_name='declines',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'volunteers_task_decline'
        unique_together = [['volunteer', 'volunteer_task']]

    def __str__(self):
        return f"{self.volunteer} declined task {self.volunteer_task_id}"


class Reward(models.Model):
    """Redeemable reward catalog for volunteers."""

    name = models.CharField(max_length=120, unique=True)
    required_points = models.PositiveIntegerField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'volunteers_reward'
        ordering = ['required_points', 'name']

    def __str__(self):
        return f"{self.name} ({self.required_points} pts)"


class Redemption(models.Model):
    """Tracks reward redemptions by user."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reward_redemptions',
    )
    reward = models.ForeignKey(
        Reward,
        on_delete=models.CASCADE,
        related_name='redemptions',
    )
    points_spent = models.PositiveIntegerField()
    date_redeemed = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'volunteers_redemption'
        ordering = ['-date_redeemed']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'reward'],
                name='volunteers_unique_reward_per_user',
            ),
        ]

    def __str__(self):
        return f"{self.user_id} redeemed {self.reward_id}"
