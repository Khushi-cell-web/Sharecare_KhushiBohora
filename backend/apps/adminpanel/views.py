"""Admin panel: reports, user verification, suspension (admin-only)."""
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.users.models import User, UserProfile
from apps.users.permissions import IsAdmin
from apps.donations.models import DonationOffer, DonationRequest
from apps.notifications.models import Notification
from apps.volunteers.models import VolunteerTask

from .models import ActivityLog, Report, UserSuspension
from .serializers import (
    ActivityLogSerializer,
    AdminUserSerializer,
    ReportSerializer,
    UserProfileVerificationSerializer,
    UserSuspensionSerializer,
)


def log_activity(actor, action, message, target_type='', target_id=None):
    """Helper to create an ActivityLog entry."""
    ActivityLog.objects.create(
        actor=actor if actor and actor.is_authenticated else None,
        action=action,
        message=message,
        target_type=target_type,
        target_id=target_id,
    )


class ReportListCreateView(generics.ListCreateAPIView):
    """List reports (admin) or create report (authenticated)."""
    serializer_class = ReportSerializer

    def get_queryset(self):
        if getattr(self.request.user, 'role', None) == 'admin':
            return Report.objects.select_related('reporter', 'reported_user').order_by('-created_at')
        return Report.objects.filter(reporter=self.request.user).order_by('-created_at')

    def get_permissions(self):
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)


class VerificationListView(generics.ListAPIView):
    """Admin: list profiles by verification status (default: pending)."""
    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = UserProfileVerificationSerializer

    def get_queryset(self):
        status_filter = self.request.query_params.get('status', 'pending')
        return UserProfile.objects.filter(
            verification_status=status_filter
        ).select_related('user').order_by('-updated_at')


class VerificationDetailView(generics.RetrieveUpdateAPIView):
    """Admin: update a single user's verification status."""
    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = UserProfileVerificationSerializer
    queryset = UserProfile.objects.select_related('user')

    def perform_update(self, serializer):
        profile = serializer.save()
        log_activity(
            self.request.user,
            'verification_update',
            f'Verification for {profile.user.username} set to {profile.verification_status}.',
            target_type='user_profile',
            target_id=profile.pk,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdmin])
def approve_ngo(request, pk):
    """POST /api/admin/approve-ngo/<id>/ - Approve or reject NGO verification."""
    try:
        profile = UserProfile.objects.get(pk=pk, user__role='ngo')
    except UserProfile.DoesNotExist:
        return Response({'detail': 'NGO profile not found.'}, status=status.HTTP_404_NOT_FOUND)

    action = request.data.get('action', 'approve')  # approve | reject
    notes = request.data.get('notes', '')
    from django.utils import timezone

    from apps.notifications.tasks import notify_verification_updated

    if action == 'approve':
        profile.verification_status = 'verified'
        profile.verified_at = timezone.now()
        profile.verification_notes = notes
        profile.save()
        notify_verification_updated(profile.user, 'verified', notes)
        log_activity(request.user, 'verification_update', f'Approved NGO {profile.user.username}.', 'user_profile', profile.pk)
        return Response({'status': 'approved'})
    elif action == 'reject':
        profile.verification_status = 'rejected'
        profile.verification_notes = notes
        profile.save()
        notify_verification_updated(profile.user, 'rejected', notes)
        log_activity(request.user, 'verification_update', f'Rejected NGO {profile.user.username}.', 'user_profile', profile.pk)
        return Response({'status': 'rejected'})
    return Response({'detail': 'action must be approve or reject'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_dashboard(request):
    """Admin: system monitoring stats."""
    if getattr(request.user, 'role', None) != 'admin':
        return Response({'detail': 'Admin only.'}, status=status.HTTP_403_FORBIDDEN)
    from django.contrib.auth import get_user_model
    from django.db.models import Sum
    from django.db.models.functions import TruncMonth
    from apps.payments.models import DonationTransaction

    User = get_user_model()

    # Top donors
    from django.db.models import Count
    top_donors = list(
        DonationTransaction.objects.filter(status='completed')
        .values('user__username')
        .annotate(total=Sum('amount'))
        .order_by('-total')[:10]
    )

    # Monthly totals
    monthly = list(
        DonationTransaction.objects.filter(status='completed')
        .annotate(month=TruncMonth('created_at'))
        .values('month')
        .annotate(total=Sum('amount'))
        .order_by('-month')[:12]
    )

    return Response({
        'users_total': User.objects.count(),
        'donation_requests_total': DonationRequest.objects.count(),
        'donation_offers_total': DonationOffer.objects.count(),
        'volunteer_tasks_total': VolunteerTask.objects.count(),
        'notifications_total': Notification.objects.count(),
        'reports_pending': Report.objects.filter(status='pending').count(),
        'total_donations': DonationTransaction.objects.filter(status='completed').aggregate(s=Sum('amount'))['s'] or 0,
        'active_campaigns': DonationRequest.objects.filter(status='open').count(),
        'top_donors': top_donors,
        'monthly_totals': [{'month': str(m['month']), 'total': float(m['total'])} for m in monthly],
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsAdmin])
def admin_analytics(request):
    """GET /api/admin/analytics/ - Aggregate analytics for admin dashboard."""
    from django.db.models import Sum
    from django.db.models.functions import TruncMonth
    from apps.payments.models import DonationTransaction

    total_donations = DonationTransaction.objects.filter(status='completed').aggregate(s=Sum('amount'))['s'] or 0
    monthly = list(
        DonationTransaction.objects.filter(status='completed')
        .annotate(month=TruncMonth('created_at'))
        .values('month')
        .annotate(total=Sum('amount'))
        .order_by('-month')[:12]
    )
    top_donors = list(
        DonationTransaction.objects.filter(status='completed')
        .values('user__username')
        .annotate(total=Sum('amount'))
        .order_by('-total')[:10]
    )
    return Response({
        'total_donations': float(total_donations),
        'active_campaigns': DonationRequest.objects.filter(status='open').count(),
        'monthly_totals': [{'month': str(m['month']), 'total': float(m['total'])} for m in monthly],
        'top_donors': top_donors,
    })


class AdminUserListView(generics.ListAPIView):
    """Admin: list all users with roles and verification summary."""

    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        return User.objects.select_related('profile').order_by('username')


class AdminUserDetailView(generics.RetrieveAPIView):
    """Admin: retrieve single user."""

    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = AdminUserSerializer
    queryset = User.objects.select_related('profile')


class UserSuspensionListCreateView(generics.ListCreateAPIView):
    """Admin: list and create user suspensions."""

    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = UserSuspensionSerializer

    def get_queryset(self):
        return UserSuspension.objects.select_related('user', 'suspended_by').order_by('-suspended_at')

    def perform_create(self, serializer):
        suspension = serializer.save(suspended_by=self.request.user)
        # Deactivate user when suspension is active
        if suspension.is_active:
            suspension.user.is_active = False
            suspension.user.save(update_fields=['is_active'])
        log_activity(
            self.request.user,
            'user_suspended',
            f'User {suspension.user.username} suspended.',
            target_type='user',
            target_id=suspension.user_id,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdmin])
def unsuspend_user(request, pk):
    """Admin: mark latest active suspension as inactive and reactivate user."""

    try:
        user = User.objects.get(pk=pk)
    except User.DoesNotExist:
        return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

    suspension = (
        UserSuspension.objects.filter(user=user, is_active=True)
        .order_by('-suspended_at')
        .first()
    )
    if not suspension:
        return Response({'detail': 'No active suspension.'}, status=status.HTTP_400_BAD_REQUEST)

    suspension.is_active = False
    suspension.save(update_fields=['is_active'])
    user.is_active = True
    user.save(update_fields=['is_active'])

    log_activity(
        request.user,
        'user_unsuspended',
        f'User {user.username} unsuspended.',
        target_type='user',
        target_id=user.pk,
    )
    return Response({'status': 'ok'})


class ReportDetailView(generics.RetrieveUpdateAPIView):
    """Admin: update report status and notes."""

    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = ReportSerializer
    queryset = Report.objects.select_related('reporter', 'reported_user')

    def perform_update(self, serializer):
        report = serializer.save()
        log_activity(
            self.request.user,
            'report_updated',
            f'Report #{report.pk} set to {report.status}.',
            target_type='report',
            target_id=report.pk,
        )


class ActivityLogListView(generics.ListAPIView):
    """Admin: list activity logs (most recent first)."""

    permission_classes = [IsAuthenticated, IsAdmin]
    serializer_class = ActivityLogSerializer

    def get_queryset(self):
        return ActivityLog.objects.select_related('actor').order_by('-created_at')
