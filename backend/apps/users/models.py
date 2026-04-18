"""
Users app: User, UserProfile, roles, authentication, organization verification.
"""
import secrets
from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


def _default_expires_at():
    from datetime import timedelta
    return timezone.now() + timedelta(minutes=30)


def _default_expires_at_10min():
    from datetime import timedelta
    return timezone.now() + timedelta(minutes=10)


class User(AbstractUser):
    """ShareCare user with role (Donor, NGO, Volunteer, Admin)."""
    ROLE_CHOICES = [
        ('donor', 'Donor'),
        ('ngo', 'NGO/Hospital'),
        ('volunteer', 'Volunteer'),
        ('admin', 'Admin'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='donor')
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True)
    organization = models.CharField(max_length=255, blank=True)
    points = models.IntegerField(default=0)

    class Meta:
        db_table = 'api_user'

    def __str__(self):
        if getattr(self, 'is_superuser', False) or self.role == 'admin':
            return self.username
        return f"{self.username} ({self.get_role_display()})"


class UserProfile(models.Model):
    """Extended profile: verification status for organizations (NGO/Hospital)."""
    VERIFICATION_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
    ]
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
    )
    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_STATUS_CHOICES,
        default='pending',
    )
    verification_id = models.CharField(
        max_length=255,
        blank=True,
        help_text='NGO/Hospital registration or license ID submitted for verification',
    )
    verification_notes = models.TextField(blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    location = models.CharField(max_length=255, blank=True, default='', help_text='City or area for matchmaking')

    last_blood_donation = models.DateTimeField(null=True, blank=True)
    is_organ_pledged = models.BooleanField(default=False)
    organ_pledge_details = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users_userprofile'

    def __str__(self):
        return f"{self.user.username} - {self.get_verification_status_display()}"


class PasswordResetOTP(models.Model):
    """One-time 6-digit code for password reset. Expires in 10 minutes."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='password_reset_otps',
    )
    otp = models.CharField(max_length=6, unique=True, db_index=True)
    expires_at = models.DateTimeField(default=_default_expires_at_10min)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'users_passwordresetotp'
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.user.email}"

    @classmethod
    def create_for_user(cls, user):
        """Create a new 6-digit OTP for user; invalidates any existing OTPs for that user."""
        # Prevent multiple OTP spam (limit to 1 request per minute)
        recent_otp = cls.objects.filter(user=user).order_by('-created_at').first()
        from datetime import timedelta
        if recent_otp and timezone.now() < recent_otp.created_at + timedelta(minutes=1):
            raise ValueError("Wait a minute before requesting a new OTP.")

        cls.objects.filter(user=user).delete()
        import random
        otp = ''.join(random.choices('0123456789', k=6))
        return cls.objects.create(user=user, otp=otp)

    def is_valid(self):
        return timezone.now() < self.expires_at


class BloodDonation(models.Model):
    """Registered blood donation via Life Donations flow (form + 90-day rule)."""

    BLOOD_GROUP_CHOICES = [
        ('A+', 'A+'),
        ('A-', 'A-'),
        ('B+', 'B+'),
        ('B-', 'B-'),
        ('O+', 'O+'),
        ('O-', 'O-'),
        ('AB+', 'AB+'),
        ('AB-', 'AB-'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blood_donations',
    )
    full_name = models.CharField(max_length=255)
    age = models.PositiveSmallIntegerField()
    blood_group = models.CharField(max_length=8, choices=BLOOD_GROUP_CHOICES)
    contact_number = models.CharField(max_length=32)
    first_time_donor = models.BooleanField(default=False)
    last_donation_declared = models.DateField(
        null=True,
        blank=True,
        help_text='Self-reported last donation (null if first-time donor).',
    )
    health_no_illness = models.BooleanField(default=False)
    health_not_on_medication = models.BooleanField(default=False)
    health_meets_weight_requirements = models.BooleanField(default=False)
    consent_information_correct = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'users_blood_donation'
        ordering = ['-created_at']

    def __str__(self):
        return f'BloodDonation user={self.user_id} {self.blood_group} @ {self.created_at}'


class OrganPledge(models.Model):
    """Organ donation pledge with consent (one row per user; updated on re-submit)."""

    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('prefer_not_say', 'Prefer not to say'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='organ_pledge',
    )
    full_name = models.CharField(max_length=255)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES)
    address = models.TextField()
    contact_number = models.CharField(max_length=32)
    email = models.EmailField()
    organs = models.JSONField(
        default=list,
        help_text='List of organ identifiers, e.g. ["Heart","Kidney"].',
    )
    emergency_contact_name = models.CharField(max_length=255)
    emergency_contact_phone = models.CharField(max_length=32)
    medical_notes = models.TextField(blank=True, default='')
    consent_organ_donation = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users_organ_pledge'

    def __str__(self):
        return f'OrganPledge user={self.user_id}'

