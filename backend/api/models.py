from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """ShareCare user with role (Donor, NGO, Volunteer, Admin)."""
    ROLE_CHOICES = [
        ('donor', 'Donor'),
        ('ngo', 'NGO/Hospital'),
        ('volunteer', 'Volunteer'),
        ('admin', 'Admin'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='donor')
    phone = models.CharField(max_length=20, blank=True)
    organization = models.CharField(max_length=255, blank=True)

    class Meta:
        db_table = 'api_user'

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"


class DonationRequest(models.Model):
    """Request for donations from NGOs/Hospitals."""
    CATEGORY_CHOICES = [
        ('food', 'Food'),
        ('clothes', 'Clothes'),
        ('books', 'Books'),
        ('funds', 'Funds'),
        ('blood', 'Blood'),
        ('organ', 'Organ'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('fulfilled', 'Fulfilled'),
        ('closed', 'Closed'),
    ]
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    quantity_needed = models.PositiveIntegerField(default=1)
    location = models.CharField(max_length=255)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='donation_requests_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_donation_request'
        ordering = ['-created_at']

    def __str__(self):
        return self.title


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
    donor = models.ForeignKey(
        User,
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
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_donation_offer'
        ordering = ['-created_at']
        unique_together = [['donor', 'donation_request']]

    def __str__(self):
        return f"{self.donor.username} -> {self.donation_request.title}"


class VolunteerTask(models.Model):
    """Task assigned to a Volunteer for a DonationRequest (e.g. pickup/delivery)."""
    TASK_STATUS_CHOICES = [
        ('assigned', 'Assigned'),
        ('picked', 'Picked'),
        ('delivered', 'Delivered'),
    ]
    volunteer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='volunteer_tasks',
    )
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.CASCADE,
        related_name='volunteer_tasks',
    )
    donation_offer = models.ForeignKey(
        DonationOffer,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='volunteer_tasks',
    )
    pickup_location = models.CharField(max_length=255)
    delivery_location = models.CharField(max_length=255)
    task_status = models.CharField(
        max_length=20,
        choices=TASK_STATUS_CHOICES,
        default='assigned',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_volunteer_task'
        ordering = ['-created_at']

    def __str__(self):
        return f"Task #{self.pk} - {self.volunteer.username} ({self.task_status})"


class Notification(models.Model):
    """Notifications for users about donation and volunteer activities."""
    NOTIFICATION_TYPES = [
        ('donation_available', 'New donation available nearby'),
        ('offer_accepted', 'Volunteer accepted your donation'),
        ('donation_picked', 'Donation picked up'),
        ('donation_delivered', 'Donation delivered'),
        ('payment_successful', 'Payment successful'),
        ('offer_received', 'You received a new donation offer'),
        ('task_assigned', 'New task assigned to you'),
        ('task_completed', 'Task completed successfully'),
    ]
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    
    # Optional foreign keys for context
    donation_request = models.ForeignKey(
        DonationRequest,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
    )
    donation_offer = models.ForeignKey(
        DonationOffer,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
    )
    volunteer_task = models.ForeignKey(
        VolunteerTask,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='notifications',
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'api_notification'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'is_read']),
        ]

    def __str__(self):
        return f"[{self.get_notification_type_display()}] {self.title} -> {self.user.username}"
