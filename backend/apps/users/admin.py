from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils import timezone

from .models import BloodDonation, OrganPledge, User, UserProfile


@admin.action(description="Approve selected organizations")
def approve_organizations(modeladmin, request, queryset):
    """
    Quick action in Django admin: approve selected NGO/Hospital profiles.
    Updates verification_status to verified and sets verified_at.
    """
    from apps.notifications.tasks import notify_verification_updated

    count = 0
    for profile in queryset.select_related('user'):
        if profile.verification_status == 'verified':
            continue
        profile.verification_status = 'verified'
        profile.verified_at = timezone.now()
        profile.verification_notes = profile.verification_notes or ''
        profile.save(update_fields=['verification_status', 'verified_at', 'verification_notes'])
        if getattr(profile.user, 'role', None) == 'ngo':
            notify_verification_updated(profile.user, 'verified', profile.verification_notes)
        count += 1
    modeladmin.message_user(request, f"Approved {count} organization profile(s).")


@admin.action(description="Reject selected organizations")
def reject_organizations(modeladmin, request, queryset):
    """
    Quick action in Django admin: reject selected NGO/Hospital profiles.
    Sets verification_status to rejected.
    """
    from apps.notifications.tasks import notify_verification_updated

    count = 0
    for profile in queryset.select_related('user'):
        if profile.verification_status == 'rejected':
            continue
        profile.verification_status = 'rejected'
        profile.save(update_fields=['verification_status'])
        if getattr(profile.user, 'role', None) == 'ngo':
            notify_verification_updated(profile.user, 'rejected', profile.verification_notes or '')
        count += 1
    modeladmin.message_user(request, f"Rejected {count} organization profile(s).")


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


@admin.register(BloodDonation)
class BloodDonationAdmin(admin.ModelAdmin):
    list_display = ['user', 'full_name', 'blood_group', 'age', 'created_at']
    list_filter = ['blood_group', 'created_at']
    search_fields = ['user__username', 'full_name', 'contact_number']
    readonly_fields = ['created_at']


@admin.register(OrganPledge)
class OrganPledgeAdmin(admin.ModelAdmin):
    list_display = ['user', 'full_name', 'email', 'updated_at']
    search_fields = ['user__username', 'full_name', 'email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'verification_status', 'verification_id', 'verified_at', 'updated_at']
    list_filter = ['verification_status']
    search_fields = ['user__username', 'verification_id', 'verification_notes']
    actions = [approve_organizations, reject_organizations]
