"""Admin panel serializers (reports, verification, suspension)."""
from rest_framework import serializers

from apps.users.models import User, UserProfile

from .models import ActivityLog, Report, UserSuspension


class ReportSerializer(serializers.ModelSerializer):
    report_type_display = serializers.CharField(source='get_report_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'reporter', 'reported_user', 'report_type', 'report_type_display',
            'description', 'status', 'status_display', 'admin_notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['reporter', 'created_at', 'updated_at']


class UserProfileVerificationSerializer(serializers.ModelSerializer):
    """Admin-only: update verification status."""
    username = serializers.CharField(source='user.username', read_only=True)
    verification_status_display = serializers.CharField(
        source='get_verification_status_display', read_only=True
    )

    class Meta:
        model = UserProfile
        fields = [
            'id', 'user', 'username', 'verification_status', 'verification_status_display',
            'verification_id', 'verification_notes', 'verified_at', 'updated_at',
        ]
        read_only_fields = ['user', 'verified_at', 'updated_at']


class AdminUserSerializer(serializers.ModelSerializer):
    """Lightweight user summary for admin UI."""

    role_display = serializers.CharField(source='get_role_display', read_only=True)
    verification_status = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'role',
            'role_display',
            'is_active',
            'date_joined',
            'last_login',
            'phone',
            'organization',
            'verification_status',
        ]

    def get_verification_status(self, obj):
        profile = getattr(obj, 'profile', None)
        return getattr(profile, 'verification_status', None)


class UserSuspensionSerializer(serializers.ModelSerializer):
    user_username = serializers.CharField(source='user.username', read_only=True)
    suspended_by_username = serializers.CharField(source='suspended_by.username', read_only=True)

    class Meta:
        model = UserSuspension
        fields = [
            'id',
            'user',
            'user_username',
            'reason',
            'suspended_by',
            'suspended_by_username',
            'suspended_at',
            'expires_at',
            'is_active',
        ]
        read_only_fields = ['suspended_by', 'suspended_at']


class ActivityLogSerializer(serializers.ModelSerializer):
    actor_username = serializers.CharField(source='actor.username', read_only=True)
    action_display = serializers.CharField(source='get_action_display', read_only=True)

    class Meta:
        model = ActivityLog
        fields = [
            'id',
            'actor',
            'actor_username',
            'action',
            'action_display',
            'message',
            'target_type',
            'target_id',
            'created_at',
        ]
        read_only_fields = ['actor', 'created_at']
