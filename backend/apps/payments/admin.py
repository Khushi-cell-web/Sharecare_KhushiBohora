from django.contrib import admin
from .models import DonationTransaction, PaymentTransaction


@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'amount', 'currency', 'gateway', 'status', 'created_at']
    list_filter = ['gateway', 'status']


@admin.register(DonationTransaction)
class DonationTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'amount', 'currency', 'donation_type', 'status', 'created_at']
    list_filter = ['status', 'currency']
