"""Volunteers app: task accept, list, update status, pending tasks, claim/decline."""
from django.contrib.auth import get_user_model
from django.db import transaction, models
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError

from apps.users.permissions import IsVolunteer
from apps.donations.models import DonationRequest
from apps.donations.serializers import DonationRequestSerializer

from .models import Redemption, Reward, VolunteerTask, VolunteerTaskDecline
from .serializers import RedeemRewardSerializer, RedemptionSerializer, RewardSerializer, VolunteerTaskSerializer

User = get_user_model()


def _rank_for_points(points):
    if points >= 150:
        return 'Top Contributor'
    if points >= 51:
        return 'Active'
    return 'Beginner'


def _sync_donation_status_from_task(task, *, save_fields=None):
    """Mirror volunteer task status back onto the donation record for tracking."""
    if not task.donation_id:
        return

    donation = task.donation
    next_status = {
        'assigned': 'assigned',
        'picked': 'picked_up',
        'in_transit': 'in_transit',
        'delivered': 'completed',
    }.get(task.task_status)

    if next_status is None:
        return

    changed_fields = []
    if donation.status != next_status:
        donation.status = next_status
        changed_fields.append('status')
    if task.volunteer_id and donation.assigned_volunteer_id != task.volunteer_id:
        donation.assigned_volunteer = task.volunteer
        changed_fields.append('assigned_volunteer')

    if changed_fields:
        changed_fields.append('updated_at')
        donation.save(update_fields=changed_fields)


class VolunteerTaskAcceptView(generics.CreateAPIView):
    """Volunteer creates a task (legacy). Prefer claiming a pending task when one exists."""
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = VolunteerTaskSerializer

    def perform_create(self, serializer):
        dr = serializer.validated_data.get('donation_request')
        dr_id = dr.id if hasattr(dr, 'id') else dr
        if VolunteerTask.objects.filter(
            donation_request_id=dr_id,
            volunteer__isnull=True,
            task_status='pending_volunteer',
        ).exists():
            raise ValidationError(
                {
                    'donation_request': 'A pickup task is already waiting for volunteers. Open Pending pickups and tap Claim.',
                }
            )
        serializer.save(volunteer=self.request.user)


class VolunteerTaskListView(generics.ListAPIView):
    """List volunteer's claimed tasks."""
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = VolunteerTaskSerializer

    def get_queryset(self):
        return VolunteerTask.objects.filter(volunteer=self.request.user).select_related(
            'donation_request',
            'donation_offer',
            'donation_offer__donor',
            'donation',
            'donation__donor',
        ).order_by('-created_at')


class VolunteerTaskDetailView(generics.RetrieveUpdateAPIView):
    """Retrieve or update task status (e.g. picked, in_transit, delivered)."""
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = VolunteerTaskSerializer

    def get_queryset(self):
        return VolunteerTask.objects.filter(volunteer=self.request.user)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        previous_status = instance.task_status

        response = super().update(request, *args, **kwargs)

        points_earned_now = 0

        # Only award points when status transitions to delivered.
        if previous_status != 'delivered':
            with transaction.atomic():
                # Keep row locking to prevent duplicate point awards, but avoid
                # nullable outer joins in FOR UPDATE queries on PostgreSQL.
                task = VolunteerTask.objects.select_for_update().get(pk=instance.pk)

                _sync_donation_status_from_task(task)

                if task.task_status == 'delivered':
                    if task.donation_id:
                        # Award donor points for completed donation in volunteer flow.
                        User.objects.filter(pk=task.donation.donor_id).update(
                            points=models.F('points') + 15,
                        )
                        try:
                            from apps.notifications.models import Notification

                            Notification.objects.create(
                                user=task.donation.donor,
                                notification_type='system',
                                title='Points earned',
                                message='+15 points earned for your completed donation.',
                                target_id=task.id,
                                target_type='volunteer_task',
                            )
                        except Exception:
                            pass

                        # Prevent duplicate points at Donation model-level for this flow.
                        task.donation.points_awarded = True
                        task.donation.save(update_fields=['points_awarded', 'updated_at'])
                    elif task.donation_offer_id and task.donation_offer.status != 'completed':
                        task.donation_offer.status = 'completed'
                        task.donation_offer.save(update_fields=['status', 'updated_at'])

                        # Award donor points for completed offer flow.
                        User.objects.filter(pk=task.donation_offer.donor_id).update(
                            points=models.F('points') + 15,
                        )
                        try:
                            from apps.notifications.models import Notification

                            Notification.objects.create(
                                user=task.donation_offer.donor,
                                notification_type='system',
                                title='Points earned',
                                message='+15 points earned for your completed donation.',
                                target_id=task.id,
                                target_type='volunteer_task',
                            )
                        except Exception:
                            pass

                    if not task.points_awarded and task.volunteer_id:
                        points_earned_now = task.completion_points()
                        volunteer = task.volunteer
                        volunteer.points = max(0, volunteer.points + points_earned_now)
                        volunteer.save(update_fields=['points'])
                        task.points_awarded = True
                        task.points_earned = points_earned_now
                        task.save(update_fields=['points_awarded', 'points_earned', 'updated_at'])

        updated_task = self.get_object()
        response.data = VolunteerTaskSerializer(updated_task).data
        request.user.refresh_from_db()
        response.data['volunteer_points'] = request.user.points
        response.data['points_earned_now'] = points_earned_now
        return response


class VolunteerPointsView(generics.GenericAPIView):
    """Current volunteer points and rank."""

    permission_classes = [IsAuthenticated, IsVolunteer]

    def get(self, request):
        points = max(0, int(getattr(request.user, 'points', 0) or 0))
        return Response({'points': points, 'rank': _rank_for_points(points)})


class RewardListView(generics.ListAPIView):
    """Active rewards list for redemption."""

    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = RewardSerializer

    def get_queryset(self):
        return Reward.objects.filter(is_active=True).order_by('required_points', 'name')


class RedemptionHistoryView(generics.ListAPIView):
    """Redemption history for current volunteer."""

    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = RedemptionSerializer

    def get_queryset(self):
        return Redemption.objects.filter(user=self.request.user).select_related('reward').order_by('-date_redeemed')


class RedeemRewardView(generics.GenericAPIView):
    """Redeem a reward by spending points."""

    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = RedeemRewardSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        reward = get_object_or_404(Reward, pk=serializer.validated_data['reward_id'], is_active=True)

        with transaction.atomic():
            user = User.objects.select_for_update().get(pk=request.user.pk)

            if Redemption.objects.filter(user=user, reward=reward).exists():
                return Response(
                    {'detail': 'You have already redeemed this reward.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if user.points < reward.required_points:
                return Response(
                    {'detail': 'Not enough points to redeem this reward.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user.points -= reward.required_points
            if user.points < 0:
                user.points = 0
            user.save(update_fields=['points'])

            redemption = Redemption.objects.create(
                user=user,
                reward=reward,
                points_spent=reward.required_points,
            )

        payload = RedemptionSerializer(redemption).data
        return Response(
            {
                'detail': 'Reward redeemed successfully.',
                'points': user.points,
                'rank': _rank_for_points(user.points),
                'redemption': payload,
            },
            status=status.HTTP_201_CREATED,
        )


class VolunteerPendingTasksView(generics.ListAPIView):
    """
    GET /api/volunteers/pending-tasks/
    Pickup tasks waiting for a volunteer (created when NGO accepts material + volunteer pickup).
    """
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = VolunteerTaskSerializer

    def get_queryset(self):
        declined = VolunteerTaskDecline.objects.filter(volunteer=self.request.user).values_list(
            'volunteer_task_id', flat=True
        )
        return (
            VolunteerTask.objects.filter(volunteer__isnull=True, task_status='pending_volunteer')
            .exclude(pk__in=declined)
            .select_related(
                'donation_request',
                'donation_offer',
                'donation_offer__donor',
                'donation',
                'donation__donor',
            )
            .order_by('-created_at')
        )


class VolunteerAvailableRequestsView(generics.ListAPIView):
    """
    GET /api/volunteers/available-requests/
    Legacy: donation requests with accepted offer and no VolunteerTask row yet.
    """
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = DonationRequestSerializer

    def get_queryset(self):
        any_task_ids = VolunteerTask.objects.values_list('donation_request_id', flat=True).distinct()
        return (
            DonationRequest.objects.filter(offers__status='accepted', status__in=['open', 'matched'])
            .exclude(id__in=any_task_ids)
            .select_related('created_by')
            .distinct()
            .order_by('-created_at')
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsVolunteer])
def volunteer_task_claim(request, pk):
    """Assign this volunteer to a pending pickup task."""
    try:
        task = VolunteerTask.objects.select_related('donation_request').get(
            pk=pk,
            volunteer__isnull=True,
            task_status='pending_volunteer',
        )
    except VolunteerTask.DoesNotExist:
        return Response({'detail': 'Task is not available to claim.'}, status=status.HTTP_404_NOT_FOUND)
    task.volunteer = request.user
    task.task_status = 'assigned'
    task.save(update_fields=['volunteer', 'task_status', 'updated_at'])
    return Response(VolunteerTaskSerializer(task).data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated, IsVolunteer])
def volunteer_task_decline(request, pk):
    """Hide a pending task from this volunteer's list."""
    task = get_object_or_404(
        VolunteerTask,
        pk=pk,
        volunteer__isnull=True,
        task_status='pending_volunteer',
    )
    VolunteerTaskDecline.objects.get_or_create(volunteer=request.user, volunteer_task=task)
    return Response({'detail': 'Task hidden from your list.'}, status=status.HTTP_200_OK)
