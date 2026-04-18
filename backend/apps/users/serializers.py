"""User serializers: registration, profile, verification."""
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import UserProfile

User = get_user_model()


class UserProfileSerializer(serializers.ModelSerializer):
    verification_status_display = serializers.CharField(
        source='get_verification_status_display', read_only=True
    )

    class Meta:
        model = UserProfile
        fields = [
            'verification_status', 'verification_status_display',
            'verification_id', 'verification_notes', 'verified_at',
            'location', 'updated_at',
        ]
        read_only_fields = ['verified_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'role_display', 'phone', 'organization',
            'profile', 'is_active', 'points',
        ]

    def get_profile(self, obj):
        try:
            return UserProfileSerializer(obj.profile).data
        except UserProfile.DoesNotExist:
            return None


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES, write_only=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    organization = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'role', 'phone', 'organization',
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError(
                {'password_confirm': 'Passwords do not match.'}
            )
        attrs.pop('password_confirm')
        
        email = attrs.get('email')
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError(
                {'email': 'A user with this email already exists.'}
            )

        role = attrs.get('role', 'donor')
        if role == 'ngo':
            if not (attrs.get('organization') or '').strip():
                raise serializers.ValidationError(
                    {'organization': 'Organization is required for NGO / Hospital.'}
                )
            if not (attrs.get('first_name') or '').strip():
                raise serializers.ValidationError(
                    {'first_name': 'First name is required for NGO / Hospital.'}
                )
            if not (attrs.get('last_name') or '').strip():
                raise serializers.ValidationError(
                    {'last_name': 'Last name is required for NGO / Hospital.'}
                )
        elif role == 'volunteer':
            if not (attrs.get('phone') or '').strip():
                raise serializers.ValidationError(
                    {'phone': 'Phone is required for Volunteer (for task coordination).'}
                )

        return attrs

    def create(self, validated_data):
        role = validated_data.pop('role', 'donor')
        phone = validated_data.pop('phone', '')
        organization = validated_data.pop('organization', '')
        user = User.objects.create_user(**validated_data)
        user.role = role
        user.phone = phone
        user.organization = organization
        user.save()
        # Create profile for organization verification (NGO default pending)
        UserProfile.objects.get_or_create(user=user, defaults={'verification_status': 'pending'})
        return user


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    """Update profile fields: first_name, last_name, phone, organization (no password)."""
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'phone', 'organization']

    def update(self, instance, validated_data):
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class SubmitVerificationSerializer(serializers.Serializer):
    """NGO/Hospital submits their verification (registration/license) ID."""
    verification_id = serializers.CharField(max_length=255, allow_blank=False, trim_whitespace=True)

    def validate_verification_id(self, value):
        if not (value or '').strip():
            raise serializers.ValidationError('Verification ID is required.')
        return (value or '').strip()


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(write_only=True)

    def validate_old_password(self, value):
        if not self.context['request'].user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError(
                {'new_password_confirm': 'New passwords do not match.'}
            )
        return attrs


class ForgotPasswordSerializer(serializers.Serializer):
    """Request password reset: user_id and email."""
    user_id = serializers.CharField(required=True, write_only=True)
    email = serializers.EmailField(required=True, write_only=True)


class VerifyOTPSerializer(serializers.Serializer):
    """Verify OTP: user_id, email, and otp."""
    user_id = serializers.CharField(required=True, write_only=True)
    email = serializers.EmailField(required=True, write_only=True)
    otp = serializers.CharField(required=True, write_only=True, min_length=6, max_length=6)


class ResetPasswordSerializer(serializers.Serializer):
    """Reset password after OTP verification: user_id, new_password."""
    user_id = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError(
                {'new_password_confirm': 'Passwords do not match.'}
            )
        return attrs


class GoogleLoginSerializer(serializers.Serializer):
    """Google sign-in payload containing ID token from mobile client."""

    id_token = serializers.CharField(required=True, allow_blank=False, trim_whitespace=True)
