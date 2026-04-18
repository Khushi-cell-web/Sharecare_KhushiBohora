"""Notifications app: list, mark as read, register device."""
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Notification, DeviceToken
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    """List current user's notifications."""
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_device(request):
    """POST /api/notifications/register-device/ - Register FCM device token."""
    token = request.data.get('token')
    if not token or not isinstance(token, str):
        return Response({'detail': 'token is required.'}, status=status.HTTP_400_BAD_REQUEST)
    token = token.strip()
    if len(token) < 10:
        return Response({'detail': 'Invalid token.'}, status=status.HTTP_400_BAD_REQUEST)

    DeviceToken.objects.get_or_create(
        user=request.user,
        token=token,
    )
    return Response({'status': 'ok', 'message': 'Device registered.'})


@api_view(['POST', 'PATCH'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, pk=None):
    """Mark one notification as read, or mark all as read if pk is None."""
    if pk:
        updated = Notification.objects.filter(user=request.user, pk=pk).update(is_read=True)
        if not updated:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response({'status': 'ok'})
    Notification.objects.filter(user=request.user).update(is_read=True)
    return Response({'status': 'ok', 'message': 'All marked as read.'})
