"""
Donations app: DonationRequest, DonationOffer, request status and lifecycle.
Lifecycle: open -> matched (offer accepted) -> completed.
"""
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


class DonationRequest(models.Model):
    """Request/Campaign for donations from NGOs/Hospitals."""
    CATEGORY_CHOICES = [
        ('food', 'Food'),
        ('clothes', 'Clothes'),
        ('books', 'Books'),
        ('funds', 'Funds'),
        ('blood', 'Blood'),
        ('organ', 'Organ'),
        ('other', 'Other'),
    ]
    URGENCY_CHOICES = [
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
    ]
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('matched', 'Matched'),
        ('partially_fulfilled', 'Partially Fulfilled'),
        ('fulfilled', 'Fulfilled'),
        ('completed', 'Completed'),
        ('closed', 'Closed'),
    ]
    title = models.CharField(max_length=255)
    description = models.TextField()
    image = models.ImageField(upload_to='campaigns/', blank=True, null=True, max_length=500)
    gallery_images = models.JSONField(default=list, blank=True, help_text='List of gallery image URLs')
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    quantity_needed = models.PositiveIntegerField(default=1)
    remaining_quantity = models.PositiveIntegerField(null=True, blank=True, help_text='Auto-calculated remaining quantity')
    urgency = models.CharField(max_length=10, choices=URGENCY_CHOICES, default='Medium')
    location = models.CharField(max_length=255)
    latitude = models.FloatField(null=True, blank=True, help_text='Pickup location latitude from map picker')
    longitude = models.FloatField(null=True, blank=True, help_text='Pickup location longitude from map picker')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    goal_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Fundraising goal (0 = N/A)')
    raised_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-calculated from transactions')
    extra_data = models.JSONField(default=dict, blank=True, help_text='Category-specific structured data')
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donation_requests_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_donation_request'
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if self.pk is None and self.remaining_quantity is None:
            self.remaining_quantity = self.quantity_needed
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title

    @property
    def percent_funded(self):
        if self.goal_amount and self.goal_amount > 0:
            return min(100, float(self.raised_amount / self.goal_amount * 100))
        return 0


class DonationOffer(models.Model):
    """Offer from a Donor linked to a DonationRequest."""
    TYPE_CHOICES = [
        ('material', 'Material'),
        ('money', 'Money'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
    ]
    FULFILLMENT_CHOICES = [
        ('self_dropoff', 'I will drop off myself'),
        ('volunteer_pickup', 'Request a volunteer pickup'),
    ]
    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donation_offers',
    )
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='offers',
    )
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    quantity = models.PositiveIntegerField(default=1)
    message = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    fulfillment_type = models.CharField(
        max_length=20,
        choices=FULFILLMENT_CHOICES,
        default='volunteer_pickup',
        help_text='For material donations: self drop-off vs volunteer pickup.',
    )
    pickup_location = models.CharField(
        max_length=512,
        blank=True,
        help_text='Pickup address when fulfillment_type is volunteer_pickup.',
    )
    pickup_latitude = models.FloatField(null=True, blank=True)
    pickup_longitude = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_donation_offer'
        ordering = ['-created_at']
        unique_together = [['donor', 'donation_request']]

    def __str__(self):
        return f"{self.donor.username} -> {self.donation_request.title}"


class ImpactUpdate(models.Model):
    """NGO impact updates: real-world impact with images and people helped."""
    campaign = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='impact_updates',
    )
    title = models.CharField(max_length=255)
    description = models.TextField()
    images = models.JSONField(default=list, blank=True, help_text='List of image URLs')
    people_helped = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'donations_impactupdate'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.people_helped} helped)"


class CampaignUpdate(models.Model):
    """NGO posts updates on campaign progress."""
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='campaign_updates',
    )
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='campaign_updates_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'donations_campaignupdate'
        ordering = ['-created_at']

    def __str__(self):
        return f"Update: {self.title}"


class Donation(models.Model):
    """
    Donation record: optional link to DonationRequest (fulfill request) or standalone (donation_request null).
    """
    TYPE_CHOICES = [
        ('material', 'Material'),
        ('money', 'Money'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('assigned', 'Assigned'),
        ('picked_up', 'Picked Up'),
        ('in_transit', 'In Transit'),
        ('completed', 'Completed'),
        ('expired', 'Expired'),
    ]
    FULFILLMENT_CHOICES = [
        ('self_dropoff', 'I will drop off myself'),
        ('volunteer_pickup', 'Request a volunteer pickup'),
    ]
    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donations_made',
    )
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='donations',
        null=True,
        blank=True,
        help_text='Null = general donation not tied to a specific NGO request.',
    )
    category = models.CharField(max_length=20, choices=DonationRequest.CATEGORY_CHOICES)
    donation_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    quantity = models.PositiveIntegerField(default=1)
    description = models.TextField(blank=True)
    fulfillment_type = models.CharField(
        max_length=20,
        choices=FULFILLMENT_CHOICES,
        default='self_dropoff',
    )
    pickup_location = models.CharField(max_length=512, blank=True)
    pickup_latitude = models.FloatField(null=True, blank=True)
    pickup_longitude = models.FloatField(null=True, blank=True)
    delivery_location = models.CharField(
        max_length=512,
        blank=True,
        help_text='Drop-off / recipient address for volunteer delivery (standalone).',
    )
    delivery_latitude = models.FloatField(null=True, blank=True)
    delivery_longitude = models.FloatField(null=True, blank=True)
    expiry_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Required for food donations. Item expiry datetime.',
    )
    valid_until = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Last datetime this donation should be considered valid for matching/listing.',
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    accepted_by_ngo = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='accepted_donations',
        help_text='NGO/Hospital that accepted this donation.',
    )
    assigned_volunteer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_donations'
    )
    points_awarded = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'donations_donation'
        ordering = ['-created_at']

    def __str__(self):
        return f"Donation #{self.pk} by {self.donor_id}"

    @property
    def is_expired(self):
        if self.status == 'expired':
            return True
        if self.category != 'food':
            return False
        deadline = self.valid_until or self.expiry_date
        if deadline is None:
            return False
        return deadline <= timezone.now()

    @property
    def is_near_expiry(self):
        if self.category != 'food' or self.is_expired:
            return False
        deadline = self.valid_until or self.expiry_date
        if deadline is None:
            return False
        remaining = deadline - timezone.now()
        return timedelta(0) < remaining <= timedelta(hours=24)

    @classmethod
    def expire_due_donations(cls):
        now = timezone.now()
        return cls.objects.filter(
            category='food',
            status__in=('pending', 'confirmed', 'assigned', 'picked_up', 'in_transit'),
        ).filter(
            models.Q(valid_until__lte=now)
            | (models.Q(valid_until__isnull=True) & models.Q(expiry_date__lte=now))
        ).update(status='expired', updated_at=now)

    def save(self, *args, **kwargs):
        new_completion = self.status == 'completed' and not self.points_awarded

        super().save(*args, **kwargs)

        if new_completion:
            from apps.users.models import User

            # Reward donor for each completed donation.
            User.objects.filter(pk=self.donor_id).update(
                points=models.F('points') + 15,
            )
            try:
                from apps.notifications.models import Notification

                Notification.objects.create(
                    user=self.donor,
                    notification_type='system',
                    title='Points earned',
                    message='+15 points earned for your completed donation.',
                    target_id=self.id,
                    target_type='donation',
                )
            except Exception:
                pass

            # Reward assigned volunteer when involved in fulfillment.
            if self.assigned_volunteer_id:
                User.objects.filter(pk=self.assigned_volunteer_id).update(
                    points=models.F('points') + 10,
                )

            self.points_awarded = True
            super().save(update_fields=['points_awarded'])


class DonationMatch(models.Model):
    """
    Automatic matchmaking between a donor's donation and an NGO donation request.

    Donor/receiver can accept or reject the match. When both accept, we convert
    the match into a real `DonationOffer` (accepted) so the existing lifecycle
    (matched -> volunteer tasks -> delivered/fulfilled) works.
    """

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]

    DECISION_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]

    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donation_matches_as_donor',
    )
    receiver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donation_matches_as_receiver',
    )

    donation = models.ForeignKey(
        Donation,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='matches',
    )
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='matches',
    )
    donation_offer = models.ForeignKey(
        'DonationOffer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='matches',
    )

    # Optional metadata for UI
    distance_km = models.FloatField(null=True, blank=True)

    # Decisions
    donor_decision = models.CharField(max_length=20, choices=DECISION_CHOICES, default='pending')
    receiver_decision = models.CharField(max_length=20, choices=DECISION_CHOICES, default='pending')

    # Public state for UI
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'donations_donationmatch'
        ordering = ['-created_at']

    def __str__(self):
        return f"Match #{self.pk} donor={self.donor_id} receiver={self.receiver_id}"


class BloodDonationRecord(models.Model):
    """Audit trail for blood donations (90-day rule enforcement)."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blood_donation_records',
    )
    recorded_at = models.DateTimeField(auto_now_add=True)
    source = models.CharField(
        max_length=48,
        blank=True,
        help_text='e.g. standalone, offer_delivered, payment, volunteer_delivered',
    )

    class Meta:
        db_table = 'donations_blood_donation_record'
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['user', '-recorded_at']),
        ]

    def __str__(self):
        return f"Blood record user={self.user_id} @ {self.recorded_at}"
class UserItemDonation(models.Model):
    STATUS_CHOICES = [
        ('CREATED', 'Created - Available'),
        ('REQUESTED', 'Requested by Receiver'),
        ('ACCEPTED', 'Accepted by Donor'),
        ('SCHEDULED', 'Pickup Scheduled'),
        ('ON_THE_WAY', 'On the Way (Out for Delivery)'),
        ('COMPLETED', 'Completed (Received)'),
    ]

    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=50) # e.g., Food, Clothes
    image = models.ImageField(upload_to='donations/images/', blank=True, null=True, max_length=500)
    location = models.CharField(max_length=255)
    
    donor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='p2p_donations_given')
    receiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='p2p_donations_received')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='CREATED')
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'donations_useritemdonation'
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if self.status == 'COMPLETED':
            self.is_active = False
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} ({self.status})"


class DonationStatusHistory(models.Model):
    donation = models.ForeignKey(UserItemDonation, on_delete=models.CASCADE, related_name='status_history')
    status = models.CharField(max_length=20, choices=UserItemDonation.STATUS_CHOICES)
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'donations_donationstatushistory'
        ordering = ['-timestamp']
