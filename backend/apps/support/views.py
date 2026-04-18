"""Support app: submit ticket, FAQ (static)."""
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import SupportTicket
from .serializers import SupportTicketCreateSerializer, SupportTicketSerializer

FAQ_STATIC = [
    {
        'id': 1,
        'question': 'How do I create a donation request?',
        'answer': 'Log in as an NGO/Hospital, go to your dashboard, and tap "Create Donation Request". Fill in title, description, category, quantity, and location.',
    },
    {
        'id': 2,
        'question': 'How do I donate to a request?',
        'answer': 'Browse donation requests from the Donate tab or Donor dashboard. Select a request and tap "Offer Donation". Enter your offer details and submit.',
    },
    {
        'id': 3,
        'question': 'How do I track my donation?',
        'answer': 'Go to "My Donations" from the Donor dashboard. You can see the status of each offer (pending, accepted, rejected, completed).',
    },
    {
        'id': 4,
        'question': 'How do I update my volunteer task status?',
        'answer': 'Open the task from your Volunteer dashboard, then tap "Update Task Status". You can set status to Picked or Delivered as you complete the delivery.',
    },
    {
        'id': 5,
        'question': 'Who can verify my organization?',
        'answer': 'Only admins can verify NGO/Hospital accounts. After registration, your profile stays "Pending" until an admin verifies it.',
    },
]


class SupportTicketCreateView(generics.CreateAPIView):
    """Submit a support request (authenticated)."""
    permission_classes = [IsAuthenticated]
    serializer_class = SupportTicketCreateSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ticket = serializer.save()
        return Response(
            SupportTicketSerializer(ticket).data,
            status=status.HTTP_201_CREATED,
        )


class SupportTicketListView(generics.ListAPIView):
    """List current user's support tickets."""
    permission_classes = [IsAuthenticated]
    serializer_class = SupportTicketSerializer

    def get_queryset(self):
        return SupportTicket.objects.filter(user=self.request.user).order_by('-created_at')


@api_view(['GET'])
@permission_classes([AllowAny])
def faq_list(request):
    """Static FAQ list (no auth required for read)."""
    return Response({'results': FAQ_STATIC})
