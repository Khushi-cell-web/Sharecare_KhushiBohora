from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib import messages
from django.http import HttpResponseRedirect
from django.shortcuts import get_object_or_404
from django.urls import path, reverse
from django.utils.html import format_html
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
    list_display = [
        'username',
        'email',
        'role',
        'organization',
        'user_verification_status',
        'user_verification_actions',
        'is_staff',
    ]
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

    @admin.display(description='Verification')
    def user_verification_status(self, obj):
        try:
            profile = obj.profile
        except UserProfile.DoesNotExist:
            return '-'

        status = (profile.verification_status or '').strip().lower()
        css = {
            'verified': 'sc-status-pill sc-status-verified',
            'rejected': 'sc-status-pill sc-status-rejected',
            'pending': 'sc-status-pill sc-status-pending',
        }.get(status, 'sc-status-pill')
        label = profile.get_verification_status_display()
        return format_html('<span class="{}">{}</span>', css, label)

    @admin.display(description='Verify')
    def user_verification_actions(self, obj):
        if getattr(obj, 'role', None) != 'ngo':
            return '-'

        try:
            profile = obj.profile
        except UserProfile.DoesNotExist:
            return '-'

        approve_url = reverse('admin:users_userprofile_approve', args=[profile.pk])
        reject_url = reverse('admin:users_userprofile_reject', args=[profile.pk])
        return format_html(
            '<a class="button sc-admin-btn sc-admin-btn-approve" href="{}">Approve</a> '
            '<a class="button sc-admin-btn sc-admin-btn-reject" href="{}">Reject</a>',
            approve_url,
            reject_url,
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
    list_display = [
        'user',
        'user_role',
        'verification_status_badge',
        'verification_id',
        'verified_at',
        'quick_verify_actions',
        'updated_at',
    ]
    list_filter = ['verification_status', 'user__role']
    search_fields = ['user__username', 'verification_id', 'verification_notes']
    list_select_related = ['user']
    actions = [approve_organizations, reject_organizations]

    @admin.display(description='Role', ordering='user__role')
    def user_role(self, obj):
        return obj.user.get_role_display()

    @admin.display(description='Verification', ordering='verification_status')
    def verification_status_badge(self, obj):
        status = (obj.verification_status or '').strip().lower()
        css = {
            'verified': 'sc-status-pill sc-status-verified',
            'rejected': 'sc-status-pill sc-status-rejected',
            'pending': 'sc-status-pill sc-status-pending',
        }.get(status, 'sc-status-pill')
        label = obj.get_verification_status_display()
        return format_html('<span class="{}">{}</span>', css, label)

    @admin.display(description='Actions')
    def quick_verify_actions(self, obj):
        if obj.verification_status == 'verified':
            reject_url = reverse('admin:users_userprofile_reject', args=[obj.pk])
            return format_html(
                '<a class="button sc-admin-btn sc-admin-btn-reject" href="{}">Reject</a>',
                reject_url,
            )

        approve_url = reverse('admin:users_userprofile_approve', args=[obj.pk])
        reject_url = reverse('admin:users_userprofile_reject', args=[obj.pk])
        return format_html(
            '<a class="button sc-admin-btn sc-admin-btn-approve" href="{}">Approve</a> '
            '<a class="button sc-admin-btn sc-admin-btn-reject" href="{}">Reject</a>',
            approve_url,
            reject_url,
        )

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:profile_id>/approve/',
                self.admin_site.admin_view(self.approve_profile_view),
                name='users_userprofile_approve',
            ),
            path(
                '<int:profile_id>/reject/',
                self.admin_site.admin_view(self.reject_profile_view),
                name='users_userprofile_reject',
            ),
        ]
        return custom_urls + urls

    def _apply_verification_status(self, request, profile, status_value, success_text):
        from apps.notifications.tasks import notify_verification_updated

        profile.verification_status = status_value
        if status_value == 'verified':
            profile.verified_at = timezone.now()
            update_fields = ['verification_status', 'verified_at']
        else:
            update_fields = ['verification_status']
        profile.save(update_fields=update_fields)

        if getattr(profile.user, 'role', None) == 'ngo':
            try:
                notify_verification_updated(
                    profile.user,
                    status_value,
                    profile.verification_notes or '',
                )
            except Exception:
                pass

        self.message_user(request, success_text, level=messages.SUCCESS)

    def approve_profile_view(self, request, profile_id):
        profile = get_object_or_404(UserProfile.objects.select_related('user'), pk=profile_id)
        self._apply_verification_status(
            request,
            profile,
            'verified',
            f'Approved organization profile for {profile.user.username}.',
        )
        return HttpResponseRedirect(request.META.get('HTTP_REFERER', '../'))

    def reject_profile_view(self, request, profile_id):
        profile = get_object_or_404(UserProfile.objects.select_related('user'), pk=profile_id)
        self._apply_verification_status(
            request,
            profile,
            'rejected',
            f'Rejected organization profile for {profile.user.username}.',
        )
        return HttpResponseRedirect(request.META.get('HTTP_REFERER', '../'))
