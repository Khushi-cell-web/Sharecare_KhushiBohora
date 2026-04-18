"""
Payments app: DonationTransaction, PaymentTransaction, payment gateway integration.
"""
from django.conf import settings
from django.db import models


class PaymentTransaction(models.Model):
    """Payment record for gateway (Stripe) - links to DonationTransaction on success."""
    GATEWAY_CHOICES = [
        ('stripe', 'Stripe'),
        ('esewa', 'eSewa'),
        ('mock', 'Mock'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('succeeded', 'Succeeded'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    DONATION_TYPE_CHOICES = [
        ('one_time', 'One-time'),
        ('recurring', 'Recurring'),
    ]
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='payment_transactions',
    )
    donation_request = models.ForeignKey(
        'donations.DonationRequest',
        on_delete=models.CASCADE,
        related_name='payment_transactions',
        null=True,
        blank=True,
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    gateway = models.CharField(max_length=20, choices=GATEWAY_CHOICES, default='stripe')
    transaction_id = models.CharField(max_length=255, blank=True)  # Stripe pi_xxx or payment_intent_id
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    donation_type = models.CharField(max_length=20, choices=DONATION_TYPE_CHOICES, default='one_time')
    donation_transaction = models.OneToOneField(
        'DonationTransaction',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payment_record',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payments_paymenttransaction'
        ordering = ['-created_at']


class DonationTransaction(models.Model):
    """Record of a donation transaction (one-time or recurring)."""
    TYPE_CHOICES = [
        ('one_time', 'One-time'),
        ('recurring', 'Recurring'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='donation_transactions',
    )
    donation_request = models.ForeignKey(
        'donations.DonationRequest',
        on_delete=models.CASCADE,
        related_name='transactions',
        null=True,
        blank=True,
    )
    donation_offer = models.ForeignKey(
        'donations.DonationOffer',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default='USD')
    donation_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='one_time')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_reference = models.CharField(max_length=255, blank=True)
    gateway_reference = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'payments_donationtransaction'
        ordering = ['-created_at']

    def __str__(self):
        return f"Transaction #{self.pk} - {self.amount} {self.currency}"
