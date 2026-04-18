from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import DonationOffer, DonationRequest, Notification, VolunteerTask
from .permissions import IsDonor, IsNGO, IsVolunteer
from .serializers import (
    DonationOfferSerializer,
    DonationRequestSerializer,
    NotificationSerializer,
    RegisterSerializer,
    UserSerializer,
    VolunteerTaskSerializer,
)


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """API root - health check / info."""
    return Response({
        'app': 'ShareCare API',
        'version': '1.0',
        'status': 'ok',
    })


# ----- Auth -----

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


class MeView(generics.RetrieveAPIView):
    """Current user profile and role."""
    permission_classes = [IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


# ----- Donation Requests -----

class DonationRequestListCreateView(generics.ListCreateAPIView):
    """List open donation requests (GET). Create request (POST, NGO only)."""
    serializer_class = DonationRequestSerializer

    def get_queryset(self):
        qs = DonationRequest.objects.select_related('created_by').order_by('-created_at')
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            qs = qs.filter(status=status_filter)
        else:
            qs = qs.filter(status='open')  # default: open only
        return qs

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsNGO()]
        return [AllowAny()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class DonationRequestDetailView(generics.RetrieveAPIView):
    """Retrieve a single donation request."""
    queryset = DonationRequest.objects.select_related('created_by')
    serializer_class = DonationRequestSerializer
    permission_classes = [AllowAny]


# ----- Donation Offers (Donor) -----

class DonationOfferCreateView(generics.CreateAPIView):
    """Donor offers a donation for a request."""
    permission_classes = [IsAuthenticated, IsDonor]
    serializer_class = DonationOfferSerializer

    def perform_create(self, serializer):
        serializer.save(donor=self.request.user)


class DonationOfferListView(generics.ListAPIView):
    """List donation offers (e.g. my offers)."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationOfferSerializer

    def get_queryset(self):
        return DonationOffer.objects.filter(donor=self.request.user).select_related(
            'donation_request', 'donor'
        ).order_by('-created_at')


# ----- Volunteer Tasks -----

class VolunteerTaskAcceptView(generics.CreateAPIView):
    """Volunteer accepts a task (creates VolunteerTask for a request)."""
    permission_classes = [IsAuthenticated, IsVolunteer]
    serializer_class = VolunteerTaskSerializer

    def perform_create(self, serializer):
        serializer.save(volunteer=self.request.user)


class VolunteerTaskListView(generics.ListAPIView):
    """List volunteer's tasks."""
    permission_classes = [IsAuthenticated]
    serializer_class = VolunteerTaskSerializer

    def get_queryset(self):
        return VolunteerTask.objects.filter(volunteer=self.request.user).select_related(
            'donation_request', 'donation_offer'
        ).order_by('-created_at')


class VolunteerTaskDetailView(generics.RetrieveUpdateAPIView):
    """Retrieve or update task status (e.g. picked, delivered)."""
    permission_classes = [IsAuthenticated]
    serializer_class = VolunteerTaskSerializer

    def get_queryset(self):
        return VolunteerTask.objects.filter(volunteer=self.request.user)


# ----- User-specific data -----

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_requests(request):
    """Donation requests created by current user (NGO)."""
    qs = DonationRequest.objects.filter(created_by=request.user).order_by('-created_at')
    serializer = DonationRequestSerializer(qs, many=True)
    return Response(serializer.data)


# ----- Notifications -----

class NotificationListView(generics.ListAPIView):
    """List notifications for current user."""
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


class NotificationDetailView(generics.RetrieveUpdateAPIView):
    """Retrieve or update a notification (e.g., mark as read)."""
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, pk):
    """Mark a notification as read."""
    try:
        notification = Notification.objects.get(pk=pk, user=request.user)
        notification.is_read = True
        notification.save()
        return Response(
            NotificationSerializer(notification).data,
            status=status.HTTP_200_OK,
        )
    except Notification.DoesNotExist:
        return Response(
            {'detail': 'Notification not found.'},
            status=status.HTTP_404_NOT_FOUND,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_all_notifications_read(request):
    """Mark all notifications as read for current user."""
    count = Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
    return Response(
        {'detail': f'{count} notifications marked as read.'},
        status=status.HTTP_200_OK,
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unread_notification_count(request):
    """Get count of unread notifications for current user."""
    count = Notification.objects.filter(user=request.user, is_read=False).count()
    return Response(
        {'unread_count': count},
        status=status.HTTP_200_OK,
    )
