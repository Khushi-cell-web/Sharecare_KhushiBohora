from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import DonationOffer, DonationRequest, Notification, User, VolunteerTask

UserModel = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = UserModel
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'role_display', 'phone', 'organization',
        ]


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES, write_only=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    organization = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = UserModel
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'role', 'phone', 'organization',
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match.'})
        attrs.pop('password_confirm')
        return attrs

    def create(self, validated_data):
        role = validated_data.pop('role', 'donor')
        phone = validated_data.pop('phone', '')
        organization = validated_data.pop('organization', '')
        user = UserModel.objects.create_user(**validated_data)
        user.role = role
        user.phone = phone
        user.organization = organization
        user.save()
        return user


class DonationRequestSerializer(serializers.ModelSerializer):
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DonationRequest
        fields = [
            'id', 'title', 'description', 'category', 'category_display',
            'quantity_needed', 'location', 'status', 'status_display',
            'created_by', 'created_by_username', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']


class DonationOfferSerializer(serializers.ModelSerializer):
    donor_username = serializers.CharField(source='donor.username', read_only=True)
    donation_request_title = serializers.CharField(source='donation_request.title', read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DonationOffer
        fields = [
            'id', 'donor', 'donor_username', 'donation_request', 'donation_request_title',
            'type', 'type_display', 'quantity', 'message', 'status', 'status_display',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['donor', 'created_at', 'updated_at']


class VolunteerTaskSerializer(serializers.ModelSerializer):
    volunteer_username = serializers.CharField(source='volunteer.username', read_only=True)
    donation_request_title = serializers.CharField(source='donation_request.title', read_only=True)
    task_status_display = serializers.CharField(source='get_task_status_display', read_only=True)

    class Meta:
        model = VolunteerTask
        fields = [
            'id', 'volunteer', 'volunteer_username', 'donation_request', 'donation_request_title',
            'donation_offer', 'pickup_location', 'delivery_location', 'task_status', 'task_status_display',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['volunteer', 'created_at', 'updated_at']


class NotificationSerializer(serializers.ModelSerializer):
    notification_type_display = serializers.CharField(source='get_notification_type_display', read_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'user_username', 'notification_type', 'notification_type_display',
            'title', 'message', 'is_read', 'donation_request', 'donation_offer', 'volunteer_task',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']
