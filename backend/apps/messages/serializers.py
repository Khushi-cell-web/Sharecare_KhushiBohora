"""Message and conversation serializers."""
from rest_framework import serializers

from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.username', read_only=True)
    receiver_id = serializers.SerializerMethodField()
    is_read = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id', 'conversation', 'sender', 'sender_username', 'receiver_id',
            'text', 'created_at', 'read_at', 'is_read',
            'donation_request', 'donation',
        ]
        read_only_fields = ['sender', 'created_at', 'read_at']

    def get_receiver_id(self, obj):
        c = obj.conversation
        return c.user2_id if obj.sender_id == c.user1_id else c.user1_id

    def get_is_read(self, obj):
        return obj.read_at is not None


class ConversationListSerializer(serializers.ModelSerializer):
    """List conversations with last message and other user info."""
    other_user_id = serializers.SerializerMethodField()
    other_user_username = serializers.SerializerMethodField()
    other_user_organization = serializers.SerializerMethodField()
    other_user_profile_location = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id', 'user1', 'user2', 'created_at', 'updated_at',
            'other_user_id', 'other_user_username',
            'other_user_organization', 'other_user_profile_location',
            'last_message', 'unread_count',
        ]

    def get_other_user_id(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        return other.id if other else None

    def get_other_user_username(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        return other.username if other else None

    def get_other_user_organization(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        if not other:
            return None
        return (getattr(other, 'organization', None) or '').strip() or None

    def get_other_user_profile_location(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        if not other:
            return None
        try:
            return (getattr(other.profile, 'location', None) or '').strip() or None
        except Exception:
            return None

    def get_last_message(self, obj):
        last = obj.messages.order_by('-created_at').first()
        if not last:
            return None
        return {
            'id': last.id,
            'sender_username': last.sender.username,
            'text': last.text[:100] + ('...' if len(last.text) > 100 else ''),
            'created_at': last.created_at,
        }

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 0
        return obj.messages.filter(read_at__isnull=True).exclude(sender=request.user).count()


class ConversationDetailSerializer(serializers.ModelSerializer):
    other_user_id = serializers.SerializerMethodField()
    other_user_username = serializers.SerializerMethodField()
    other_user_organization = serializers.SerializerMethodField()
    other_user_profile_location = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id', 'user1', 'user2', 'created_at', 'updated_at',
            'other_user_id', 'other_user_username',
            'other_user_organization', 'other_user_profile_location',
        ]

    def get_other_user_id(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        return other.id if other else None

    def get_other_user_username(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        return other.username if other else None

    def get_other_user_organization(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        if not other:
            return None
        return (getattr(other, 'organization', None) or '').strip() or None

    def get_other_user_profile_location(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        other = obj.other_user(request.user)
        if not other:
            return None
        try:
            return (getattr(other.profile, 'location', None) or '').strip() or None
        except Exception:
            return None
