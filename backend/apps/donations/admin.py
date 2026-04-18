from django.contrib import admin
from .models import BloodDonationRecord, Donation, DonationOffer, DonationRequest, ImpactUpdate


@admin.register(DonationRequest)
class DonationRequestAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'status', 'created_by', 'location', 'created_at']
    list_filter = ['category', 'status']
    search_fields = ['title', 'description', 'location']


@admin.register(ImpactUpdate)
class ImpactUpdateAdmin(admin.ModelAdmin):
    list_display = ['title', 'campaign', 'people_helped', 'created_at']
    list_filter = ['created_at']


@admin.register(DonationOffer)
class DonationOfferAdmin(admin.ModelAdmin):
    list_display = ['donor', 'donation_request', 'type', 'quantity', 'status', 'created_at']
    list_filter = ['type', 'status']


@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = ['donor', 'donation_request', 'category', 'donation_type', 'quantity', 'status', 'created_at']
    list_filter = ['category', 'donation_type', 'status']


@admin.register(BloodDonationRecord)
class BloodDonationRecordAdmin(admin.ModelAdmin):
    list_display = ['user', 'recorded_at', 'source']
    list_filter = ['source']
