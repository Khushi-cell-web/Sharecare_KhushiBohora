"""WebSocket consumer for real-time donation progress updates."""
import json

from asgiref.sync import sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser


class CampaignProgressConsumer(AsyncWebsocketConsumer):
    """
    WebSocket for campaign donation progress.
    Connect: ws://host/ws/campaigns/<campaign_id>/?token=<access_token>
    Receive: { type: 'donation_update', campaign_id, raised_amount, goal_amount, percent_funded }
    """

    async def connect(self):
        self.campaign_id = self.scope['url_route']['kwargs']['campaign_id']
        self.room_group_name = f'campaign_{self.campaign_id}'
        user = self.scope.get('user')

        if not user or isinstance(user, AnonymousUser):
            await self.close(code=4401)
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def donation_update(self, event):
        """Broadcast donation update to connected clients."""
        await self.send(text_data=json.dumps({
            'type': 'donation_update',
            'campaign_id': event['campaign_id'],
            'raised_amount': event['raised_amount'],
            'goal_amount': event['goal_amount'],
            'percent_funded': event['percent_funded'],
        }))
