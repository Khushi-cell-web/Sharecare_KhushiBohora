"""WebSocket consumer for real-time messaging."""
import json

from asgiref.sync import sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from django.utils import timezone

from .models import Conversation, Message


class ChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for a conversation room.
    Connect: ws://host/ws/messages/<conversation_id>/?token=<access_token>
    Send: { "text": "message content" }
    Receive: { "type": "message", "id", "sender_username", "text", "created_at" }
    """

    async def connect(self):
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_conversation_{self.conversation_id}'
        user = self.scope.get('user')

        if not user or isinstance(user, AnonymousUser):
            await self.close(code=4401)
            return

        # Verify user is participant in this conversation
        is_participant = await self._user_is_participant(user.id, self.conversation_id)
        if not is_participant:
            await self.close(code=4403)
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        user = self.scope.get('user')
        if not user or isinstance(user, AnonymousUser):
            return
        try:
            data = json.loads(text_data)
            text = (data.get('text') or '').strip()
            if not text:
                return
        except (json.JSONDecodeError, TypeError):
            return

        # Save message to DB and broadcast to group
        message = await self._create_message(user.id, text)
        if message:
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': message,
                },
            )

    async def chat_message(self, event):
        """Send message to WebSocket (broadcast from group_send)."""
        await self.send(text_data=json.dumps(event['message']))

    @database_sync_to_async
    def _user_is_participant(self, user_id, conv_id):
        from django.db.models import Q
        return Conversation.objects.filter(
            Q(user1_id=user_id) | Q(user2_id=user_id),
            pk=conv_id,
        ).exists()

    @database_sync_to_async
    def _create_message(self, user_id, text):
        from django.db.models import Q
        conv = Conversation.objects.filter(
            Q(user1_id=user_id) | Q(user2_id=user_id),
            pk=self.conversation_id,
        ).first()
        if not conv:
            return None
        msg = Message.objects.create(
            conversation=conv,
            sender_id=user_id,
            text=text,
        )
        conv.updated_at = timezone.now()
        conv.save(update_fields=['updated_at'])
        return {
            'type': 'message',
            'id': msg.id,
            'sender_id': msg.sender_id,
            'sender_username': msg.sender.username,
            'text': msg.text,
            'created_at': msg.created_at.isoformat(),
        }
