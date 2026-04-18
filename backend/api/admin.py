from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import DonationOffer, DonationRequest, Notification, User, VolunteerTask


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'email', 'role', 'organization', 'is_staff']
    list_filter = ['role', 'is_staff']
    search_fields = ['username', 'email', 'organization']
    ordering = ['username']
    filter_horizontal = BaseUserAdmin.filter_horizontal
    fieldsets = BaseUserAdmin.fieldsets + (
        ('ShareCare', {'fields': ('role', 'phone', 'organization')}),
    )
    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('ShareCare', {'fields': ('role', 'phone', 'organization')}),
    )


@admin.register(DonationRequest)
class DonationRequestAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'status', 'created_by', 'location', 'created_at']
    list_filter = ['category', 'status']
    search_fields = ['title', 'description', 'location']


@admin.register(DonationOffer)
class DonationOfferAdmin(admin.ModelAdmin):
    list_display = ['donor', 'donation_request', 'type', 'quantity', 'status', 'created_at']
    list_filter = ['type', 'status']


@admin.register(VolunteerTask)
class VolunteerTaskAdmin(admin.ModelAdmin):
    list_display = ['volunteer', 'donation_request', 'task_status', 'pickup_location', 'delivery_location', 'created_at']
    list_filter = ['task_status']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['title', 'message', 'user__username']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
