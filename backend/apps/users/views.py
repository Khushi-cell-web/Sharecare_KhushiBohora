"""Users app: auth, profile, organization verification, change password, activity history, forgot/reset password."""
import json
import logging
import re
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import urlopen

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.db import transaction
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import PasswordResetOTP
from .models import UserProfile
from .serializers import (
    ChangePasswordSerializer,
    ForgotPasswordSerializer,
    GoogleLoginSerializer,
    RegisterSerializer,
    ResetPasswordSerializer,
    SubmitVerificationSerializer,
    UserProfileUpdateSerializer,
    UserSerializer,
    VerifyOTPSerializer,
)


def _verify_google_id_token(id_token: str):
    """Validate Google ID token using Google's tokeninfo endpoint."""
    query = urlencode({'id_token': id_token})
    tokeninfo_url = f'https://oauth2.googleapis.com/tokeninfo?{query}'

    try:
        with urlopen(tokeninfo_url, timeout=10) as response:
            payload = json.loads(response.read().decode('utf-8'))
    except (HTTPError, URLError, TimeoutError, ValueError):
        return None, 'Invalid Google token.'

    issuer = payload.get('iss')
    if issuer not in ('https://accounts.google.com', 'accounts.google.com'):
        return None, 'Invalid Google token issuer.'

    allowed_audiences = getattr(settings, 'GOOGLE_OAUTH_CLIENT_IDS', []) or []
    audience = payload.get('aud', '')
    if allowed_audiences and audience not in allowed_audiences:
        return None, 'Google token audience mismatch.'

    email_verified = payload.get('email_verified')
    is_verified = email_verified is True or str(email_verified).lower() == 'true'
    if not is_verified:
        return None, 'Google account email is not verified.'

    return payload, None


def _generate_unique_username_from_email(email: str) -> str:
    User = get_user_model()
    base = re.sub(r'[^a-zA-Z0-9_]', '_', (email or '').split('@')[0]).strip('_').lower()
    if not base:
        base = 'google_user'
    base = base[:130]
    candidate = base
    suffix = 1
    while User.objects.filter(username=candidate).exists():
        suffix += 1
        candidate = f'{base[:120]}_{suffix}'
    return candidate


class RegisterView(generics.CreateAPIView):
    """Register a new user with role (Donor, NGO, Volunteer, Admin)."""
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            UserSerializer(user).data,
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    """Login - returns JWT access & refresh tokens."""
    permission_classes = [AllowAny]


class GoogleLoginView(generics.GenericAPIView):
    """Google Sign-In token exchange endpoint returning JWT tokens."""

    permission_classes = [AllowAny]
    serializer_class = GoogleLoginSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payload, error = _verify_google_id_token(serializer.validated_data['id_token'])
        if error:
            return Response({'detail': error}, status=status.HTTP_400_BAD_REQUEST)

        email = (payload.get('email') or '').strip().lower()
        if not email:
            return Response(
                {'detail': 'Google token did not include a valid email.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        first_name = (payload.get('given_name') or '').strip()
        last_name = (payload.get('family_name') or '').strip()

        User = get_user_model()
        with transaction.atomic():
            user = User.objects.filter(email__iexact=email).first()
            created = False

            if user is None:
                user = User.objects.create_user(
                    username=_generate_unique_username_from_email(email),
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    role='donor',
                )
                created = True

            # Keep basic profile details in sync, without overriding existing user edits.
            changed_fields = []
            if first_name and not user.first_name:
                user.first_name = first_name
                changed_fields.append('first_name')
            if last_name and not user.last_name:
                user.last_name = last_name
                changed_fields.append('last_name')
            if changed_fields:
                user.save(update_fields=changed_fields)

            UserProfile.objects.get_or_create(user=user, defaults={'verification_status': 'pending'})

            if not user.is_active:
                return Response(
                    {'detail': 'User account is disabled.'},
                    status=status.HTTP_403_FORBIDDEN,
                )

            refresh = RefreshToken.for_user(user)

        return Response(
            {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserSerializer(user).data,
                'created': created,
            },
            status=status.HTTP_200_OK,
        )


class MeView(generics.RetrieveUpdateAPIView):
    """Current user profile: GET or PATCH (view / update profile)."""
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ('PATCH', 'PUT'):
            return UserProfileUpdateSerializer
        return UserSerializer

    def perform_update(self, serializer):
        serializer.save()

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(UserSerializer(instance).data)


class SubmitVerificationView(generics.GenericAPIView):
    """NGO/Hospital submits verification ID (registration/license). Only when status is pending."""
    permission_classes = [IsAuthenticated]
    serializer_class = SubmitVerificationSerializer

    def post(self, request):
        if getattr(request.user, 'role', None) != 'ngo':
            return Response(
                {'detail': 'Only NGO/Hospital can submit verification ID.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            profile = request.user.profile
        except UserProfile.DoesNotExist:
            return Response(
                {'detail': 'Profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        if profile.verification_status not in ('pending', 'rejected'):
            return Response(
                {'detail': 'Verification can only be submitted when status is pending or rejected.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile.verification_id = serializer.validated_data['verification_id']
        if profile.verification_status == 'rejected':
            profile.verification_status = 'pending'
            profile.verification_notes = ''
            profile.save(update_fields=['verification_id', 'verification_status', 'verification_notes'])
        else:
            profile.save(update_fields=['verification_id'])
        return Response(
            {'detail': 'Verification ID submitted. An admin will verify your organization.'},
            status=status.HTTP_200_OK,
        )


class ChangePasswordView(generics.GenericAPIView):
    """Change password: POST with old_password, new_password, new_password_confirm."""
    permission_classes = [IsAuthenticated]
    serializer_class = ChangePasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save(update_fields=['password'])
        return Response({'detail': 'Password updated successfully.'}, status=status.HTTP_200_OK)


class ForgotPasswordView(generics.GenericAPIView):
    """Request password reset: POST with user_id and email. Sends 6-digit OTP via email."""
    permission_classes = [AllowAny]
    serializer_class = ForgotPasswordSerializer

    def post(self, request):
        logger = logging.getLogger(__name__)
        logger.info("Email received")
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email'].strip().lower()
        user_id = str(serializer.validated_data['user_id']).strip()
        User = get_user_model()
        
        from django.db.models import Q
        query = Q(username__iexact=user_id)
        if user_id.isdigit():
            query |= Q(id=user_id)
            
        user = User.objects.filter(query, email__iexact=email).first()
        if not user:
            return Response(
                {'detail': 'User not found.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        try:
            reset = PasswordResetOTP.create_for_user(user)
        except ValueError as e:
            return Response(
                {'detail': str(e)},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        logger.info("OTP generated")
        subject = 'ShareCare – Password Reset Code'
        message = (
            f'Hello,\n\n'
            f'You requested a password reset for your ShareCare account.\n\n'
            f'Your password reset code: {reset.otp}\n\n'
            f'This code expires in 10 minutes. Enter it in the app to reset your password.\n\n'
            f'If you did not request this, please ignore this email.\n\n'
            f'ShareCare Team'
        )
        try:
            sent = send_mail(
                subject,
                message,
                getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@sharecare.local'),
                [user.email],
                fail_silently=False,
            )
            
            if sent == 0:
                logger.warning('Forgot password: send_mail returned 0 for %s', user.email)
                return Response(
                    {'detail': 'Failed to send OTP. Please try again.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
            
            logger.info("Email sent successfully to %s", user.email)
            if settings.DEBUG:
                print(f"OTP for {email} is {reset.otp}")

            return Response(
                {'detail': 'OTP sent to your email'},
                status=status.HTTP_200_OK,
            )

        except Exception as e:
            logger.exception('Forgot password: failed to send email to %s: %s', user.email, e)
            print(f"Failed to send email: {e}")
            if settings.DEBUG:
                print(f"OTP for {email} is {reset.otp}")
                
            return Response(
                {'detail': 'Failed to send OTP. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class VerifyOTPView(generics.GenericAPIView):
    """Verify OTP: POST with user_id, email and otp."""
    permission_classes = [AllowAny]
    serializer_class = VerifyOTPSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email'].strip().lower()
        user_id = str(serializer.validated_data['user_id']).strip()
        otp_str = serializer.validated_data['otp'].strip()
        User = get_user_model()
        
        from django.db.models import Q
        query = Q(username__iexact=user_id)
        if user_id.isdigit():
            query |= Q(id=user_id)
            
        user = User.objects.filter(query, email__iexact=email).first()
        if not user:
            return Response(
                {'detail': 'User not found.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
            
        try:
            otp_obj = PasswordResetOTP.objects.get(user=user, otp=otp_str)
        except PasswordResetOTP.DoesNotExist:
            return Response(
                {'detail': 'Invalid OTP'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not otp_obj.is_valid():
            otp_obj.delete()
            return Response(
                {'detail': 'OTP has expired.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # OTP is valid, create a temporary session token for password reset
        # We'll use the OTP object as the session, and require email + new_password
        return Response(
            {'detail': 'OTP verified successfully. You can now reset your password.'},
            status=status.HTTP_200_OK,
        )


class ResetPasswordView(generics.GenericAPIView):
    """Reset password after OTP verification: POST with user_id, new_password, new_password_confirm."""
    permission_classes = [AllowAny]
    serializer_class = ResetPasswordSerializer

    def post(self, request):
        logger = logging.getLogger(__name__)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user_id = str(serializer.validated_data['user_id']).strip()
        new_password = serializer.validated_data['new_password']
        User = get_user_model()
        
        from django.db.models import Q
        query = Q(username__iexact=user_id)
        if user_id.isdigit():
            query |= Q(id=user_id)
            
        user = User.objects.filter(query).first()
        if not user:
            return Response(
                {'detail': 'User not found.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Check if there's a valid OTP for this user (recently verified)
        recent_otps = PasswordResetOTP.objects.filter(
            user=user,
            created_at__gte=timezone.now() - timezone.timedelta(minutes=10)
        ).order_by('-created_at')

        if not recent_otps.exists():
            return Response(
                {'detail': 'Please verify your OTP first.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Pick the latest OTP.
        otp_obj = recent_otps.first()
        if not otp_obj.is_valid():
            otp_obj.delete()
            return Response(
                {'detail': 'OTP has expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(new_password)
        user.save(update_fields=['password'])
        otp_obj.delete()  # Clean up after successful reset
        logger.info("Password updated")
        return Response(
            {'detail': 'Password updated successfully'},
            status=status.HTTP_200_OK,
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def activity_history(request):
    """Activity history for current user: donation requests created, offers made, tasks assigned."""
    from apps.donations.models import DonationOffer, DonationRequest
    from apps.volunteers.models import VolunteerTask

    user = request.user
    items = []

    if getattr(user, 'role', None) == 'ngo':
        for r in DonationRequest.objects.filter(created_by=user).order_by('-created_at')[:50]:
            items.append({
                'type': 'donation_request',
                'id': r.id,
                'title': r.title,
                'status': r.status,
                'created_at': r.created_at.isoformat() if r.created_at else None,
            })
    if getattr(user, 'role', None) == 'donor':
        for o in DonationOffer.objects.filter(donor=user).select_related('donation_request').order_by('-created_at')[:50]:
            items.append({
                'type': 'donation_offer',
                'id': o.id,
                'request_title': o.donation_request.title,
                'status': o.status,
                'created_at': o.created_at.isoformat() if o.created_at else None,
            })
    for t in VolunteerTask.objects.filter(volunteer=user).select_related('donation_request').order_by('-created_at')[:50]:
        items.append({
            'type': 'volunteer_task',
            'id': t.id,
            'request_title': t.donation_request.title,
            'status': t.task_status,
            'created_at': t.created_at.isoformat() if t.created_at else None,
        })

    items.sort(key=lambda x: x['created_at'] or '', reverse=True)
    return Response({'results': items[:50]})
