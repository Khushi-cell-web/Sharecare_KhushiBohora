"""Messages app: REST API for conversations and messages."""
from django.db.models import Q
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.users.models import User
from .models import Conversation, Message
from .serializers import (
    ConversationDetailSerializer,
    ConversationListSerializer,
    MessageSerializer,
)


def _volunteer_chat_link_exists(user_a, user_b):
    """True if one user is a volunteer assigned to a task involving the other (donor or NGO)."""
    from apps.volunteers.models import VolunteerTask

    ra, rb = getattr(user_a, 'role', ''), getattr(user_b, 'role', '')
    if 'volunteer' not in (ra, rb):
        return False
    volunteer, other = (user_a, user_b) if ra == 'volunteer' else (user_b, user_a)
    if getattr(volunteer, 'role', '') != 'volunteer':
        return False
    qs = VolunteerTask.objects.filter(volunteer=volunteer)
    if qs.filter(donation_offer__donor=other).exists():
        return True
    if qs.filter(donation__donor=other).exists():
        return True
    if qs.filter(donation_request__created_by=other).exists():
        return True
    return False


def users_may_chat(user_a, user_b):
    """Donor↔NGO always; volunteer↔donor/NGO when linked by an assigned volunteer task."""
    if user_a.id == user_b.id:
        return False
    ra, rb = getattr(user_a, 'role', ''), getattr(user_b, 'role', '')
    if {ra, rb} == {'donor', 'ngo'}:
        return True
    return _volunteer_chat_link_exists(user_a, user_b)


def _broadcast_chat_message(conv_id, payload):
    """Notify WebSocket subscribers (same group name as ChatConsumer)."""
    try:
        from asgiref.sync import async_to_sync
        from channels.layers import get_channel_layer

        channel_layer = get_channel_layer()
        if not channel_layer:
            return
        async_to_sync(channel_layer.group_send)(
            f'chat_conversation_{conv_id}',
            {'type': 'chat_message', 'message': payload},
        )
    except Exception:
        pass


def _message_ws_payload(msg):
    return {
        'type': 'message',
        'id': msg.id,
        'sender': msg.sender_id,
        'sender_id': msg.sender_id,
        'sender_username': msg.sender.username,
        'text': msg.text,
        'created_at': msg.created_at.isoformat(),
        'read_at': msg.read_at.isoformat() if msg.read_at else None,
        'is_read': msg.read_at is not None,
    }


class ConversationListView(generics.ListAPIView):
    """List current user's conversations (with last message and unread count)."""
    permission_classes = [IsAuthenticated]
    serializer_class = ConversationListSerializer

    def get_queryset(self):
        return Conversation.objects.filter(
            Q(user1=self.request.user) | Q(user2=self.request.user)
        ).order_by('-updated_at')


class ConversationCreateView(generics.GenericAPIView):
    """Get or create a 1-to-1 conversation with another user. POST body: { "other_user_id": <id> }."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        other_id = request.data.get('other_user_id')
        if other_id is None:
            return Response(
                {'detail': 'other_user_id is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            other = User.objects.get(pk=int(other_id))
        except (ValueError, User.DoesNotExist):
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        if other == request.user:
            return Response(
                {'detail': 'Cannot create conversation with yourself.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not users_may_chat(request.user, other):
            return Response(
                {
                    'detail': 'Chat is only allowed between donors, NGOs, and linked volunteers.',
                },
                status=status.HTTP_403_FORBIDDEN,
            )
        u1, u2 = (request.user, other) if request.user.id < other.id else (other, request.user)
        conv, created = Conversation.objects.get_or_create(user1=u1, user2=u2)
        serializer = ConversationDetailSerializer(conv, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class ConversationDetailView(generics.RetrieveAPIView):
    """Retrieve a conversation (only if participant)."""
    permission_classes = [IsAuthenticated]
    serializer_class = ConversationDetailSerializer

    def get_queryset(self):
        return Conversation.objects.filter(
            Q(user1=self.request.user) | Q(user2=self.request.user)
        )


class MessageListCreateView(generics.ListCreateAPIView):
    """List messages in a conversation and create a new message."""
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer

    def get_queryset(self):
        conv_id = self.kwargs.get('conversation_id')
        conv = Conversation.objects.filter(
            Q(user1=self.request.user) | Q(user2=self.request.user),
            pk=conv_id,
        ).first()
        if not conv:
            return Message.objects.none()
        return Message.objects.filter(conversation=conv).order_by('created_at')

    def perform_create(self, serializer):
        conv_id = self.kwargs.get('conversation_id')
        conv = Conversation.objects.filter(
            Q(user1=self.request.user) | Q(user2=self.request.user),
            pk=conv_id,
        ).first()
        if not conv:
            raise PermissionDenied()
        serializer.save(conversation=conv, sender=self.request.user)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_messages_read(request, conversation_id):
    """Mark all messages in the conversation (sent by the other user) as read."""
    conv = Conversation.objects.filter(
        Q(user1=request.user) | Q(user2=request.user),
        pk=conversation_id,
    ).first()
    if not conv:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
    Message.objects.filter(conversation=conv).exclude(sender=request.user).update(read_at=timezone.now())
    return Response({'status': 'ok'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_room(request):
    """POST /api/chat/room/ - create or get room between two users."""
    other_id = request.data.get('other_user_id') or request.data.get('receiver_id')
    if other_id is None:
        return Response({'detail': 'other_user_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        other = User.objects.get(pk=int(other_id))
    except (ValueError, User.DoesNotExist):
        return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
    if other == request.user:
        return Response({'detail': 'Cannot chat with yourself.'}, status=status.HTTP_400_BAD_REQUEST)
    if not users_may_chat(request.user, other):
        return Response(
            {'detail': 'Chat is not allowed with this user.'},
            status=status.HTTP_403_FORBIDDEN,
        )
    conv = Conversation.get_or_create_between(request.user, other)
    data = ConversationDetailSerializer(conv, context={'request': request}).data
    data['chat_room'] = data['id']
    return Response(data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_rooms(request):
    """GET /api/chat/rooms/ - all rooms for logged-in user."""
    qs = Conversation.objects.filter(Q(user1=request.user) | Q(user2=request.user)).order_by('-updated_at')
    return Response(ConversationListSerializer(qs, many=True, context={'request': request}).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_partners(request):
    """
    GET /api/chat/partners/ — users the current user may chat with, merged with conversation previews.
    Includes NGOs/donors from offers and volunteers/donors/NGOs from volunteer tasks.
    """
    from apps.donations.models import DonationOffer
    from apps.volunteers.models import VolunteerTask

    user = request.user
    aggregated = {}

    def ensure_entry(uid, u_obj=None):
        if uid == user.id:
            return None
        if uid not in aggregated:
            u = u_obj if u_obj is not None else User.objects.filter(pk=uid).first()
            if u is None:
                return None
            display = (f'{u.first_name} {u.last_name}'.strip() or u.username)
            aggregated[uid] = {
                'user_id': uid,
                'username': u.username,
                'display_name': display,
                'role': u.role,
                'context_subtitle': None,
                'request_id': None,
                'donation_id': None,
                'room_id': None,
                'last_message': None,
                'unread_count': 0,
            }
        return aggregated[uid]

    def set_context(entry, subtitle, req_id=None, don_id=None):
        if entry is None:
            return
        if not entry.get('context_subtitle') and subtitle:
            entry['context_subtitle'] = subtitle[:200]
        if req_id is not None and entry.get('request_id') is None:
            entry['request_id'] = req_id
        if don_id is not None and entry.get('donation_id') is None:
            entry['donation_id'] = don_id

    # Existing conversations (room + last message + unread)
    for conv in (
        Conversation.objects.filter(Q(user1=user) | Q(user2=user))
        .select_related('user1', 'user2')
        .order_by('-updated_at')
    ):
        other = conv.other_user(user)
        e = ensure_entry(other.id, other)
        if not e:
            continue
        e['room_id'] = conv.id
        last = conv.messages.order_by('-created_at').first()
        if last:
            t = last.text or ''
            e['last_message'] = {
                'id': last.id,
                'text': t[:100] + ('...' if len(t) > 100 else ''),
                'created_at': last.created_at.isoformat(),
            }
        e['unread_count'] = conv.messages.filter(read_at__isnull=True).exclude(sender=user).count()

    # Donor → NGO (requests you offered on)
    for off in DonationOffer.objects.filter(donor=user).select_related('donation_request__created_by'):
        ngo = off.donation_request.created_by
        e = ensure_entry(ngo.id, ngo)
        set_context(e, off.donation_request.title, req_id=off.donation_request_id)

    # NGO → donors (offers on your requests)
    for off in DonationOffer.objects.filter(donation_request__created_by=user).select_related(
        'donor', 'donation_request'
    ):
        d = off.donor
        e = ensure_entry(d.id, d)
        set_context(e, off.donation_request.title, req_id=off.donation_request_id)

    # Volunteer: NGO + donors from assigned tasks
    for task in VolunteerTask.objects.filter(volunteer=user).select_related(
        'donation_request__created_by',
        'donation_offer__donor',
        'donation__donor',
    ):
        if task.donation_request_id:
            ngo = task.donation_request.created_by
            e = ensure_entry(ngo.id, ngo)
            set_context(e, task.donation_request.title, req_id=task.donation_request_id)
        if task.donation_offer_id and task.donation_offer:
            don = task.donation_offer.donor
            e = ensure_entry(don.id, don)
            dr = task.donation_request or task.donation_offer.donation_request
            sub = dr.title if dr else 'Delivery'
            rid = task.donation_request_id or (
                task.donation_offer.donation_request_id if task.donation_offer else None
            )
            set_context(e, sub, req_id=rid)
        if task.donation_id and task.donation:
            don = task.donation.donor
            e = ensure_entry(don.id, don)
            set_context(e, 'Standalone donation', don_id=task.donation_id)

    # Donor / NGO → volunteer on linked tasks
    for task in VolunteerTask.objects.filter(
        Q(donation_offer__donor=user) | Q(donation__donor=user) | Q(donation_request__created_by=user),
        volunteer__isnull=False,
    ).select_related('volunteer', 'donation_request', 'donation_offer', 'donation'):
        vol = task.volunteer
        if not vol:
            continue
        e = ensure_entry(vol.id, vol)
        if task.donation_request_id:
            set_context(e, task.donation_request.title, req_id=task.donation_request_id)
        elif task.donation_id:
            set_context(e, 'Standalone donation', don_id=task.donation_id)

    items = list(aggregated.values())

    def sort_key(row):
        lm = row.get('last_message') or {}
        return lm.get('created_at') or ''

    items.sort(key=sort_key, reverse=True)
    return Response(items)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_messages(request, room_id):
    """GET /api/chat/messages/<room_id>/ - ordered messages for room."""
    conv = Conversation.objects.filter(Q(user1=request.user) | Q(user2=request.user), pk=room_id).first()
    if not conv:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
    qs = Message.objects.filter(conversation=conv).order_by('created_at')
    return Response(MessageSerializer(qs, many=True).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_send(request):
    """POST /api/chat/send/ - send message to room."""
    from apps.donations.models import Donation, DonationRequest

    room_id = request.data.get('room_id') or request.data.get('chat_room_id')
    text = (request.data.get('text') or '').strip()
    if not room_id or not text:
        return Response({'detail': 'room_id and text are required.'}, status=status.HTTP_400_BAD_REQUEST)
    conv = Conversation.objects.filter(Q(user1=request.user) | Q(user2=request.user), pk=room_id).first()
    if not conv:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

    req_id = request.data.get('request_id') or request.data.get('donation_request_id')
    don_id = request.data.get('donation_id')
    dr_fk = None
    d_fk = None
    if req_id is not None:
        try:
            dr_fk = DonationRequest.objects.filter(pk=int(req_id)).first()
        except (ValueError, TypeError):
            pass
    if don_id is not None:
        try:
            d_fk = Donation.objects.filter(pk=int(don_id)).first()
        except (ValueError, TypeError):
            pass

    msg = Message.objects.create(
        conversation=conv,
        sender=request.user,
        text=text,
        donation_request=dr_fk,
        donation=d_fk,
    )
    conv.updated_at = timezone.now()
    conv.save(update_fields=['updated_at'])
    _broadcast_chat_message(conv.id, _message_ws_payload(msg))
    return Response(MessageSerializer(msg).data, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_read(request):
    """POST /api/chat/read/ - mark messages as read in room."""
    room_id = request.data.get('room_id') or request.data.get('chat_room_id')
    if not room_id:
        return Response({'detail': 'room_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
    conv = Conversation.objects.filter(Q(user1=request.user) | Q(user2=request.user), pk=room_id).first()
    if not conv:
        return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
    Message.objects.filter(conversation=conv, read_at__isnull=True).exclude(sender=request.user).update(
        read_at=timezone.now()
    )
    return Response({'status': 'ok'})
