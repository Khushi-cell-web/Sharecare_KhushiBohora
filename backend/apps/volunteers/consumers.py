"""WebSocket: live volunteer delivery task status for donor, NGO, and volunteer."""
import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser

from .models import VolunteerTask
from .realtime import build_delivery_payload, user_can_subscribe_delivery_task


class DeliveryTaskTrackingConsumer(AsyncWebsocketConsumer):
    """
    ws://host/ws/delivery-tasks/<task_id>/?token=<access_token>
    Messages: JSON with type delivery_task_update (snapshot on connect + on each save).
    """

    async def connect(self):
        user = self.scope.get('user')
        if not user or isinstance(user, AnonymousUser):
            await self.close(code=4401)
            return
        try:
            self.task_id = int(self.scope['url_route']['kwargs']['task_id'])
        except (TypeError, ValueError):
            await self.close(code=4400)
            return
        self.group_name = f'delivery_task_{self.task_id}'

        task = await self._fetch_task()
        if task is None:
            await self.close(code=4404)
            return
        if not await database_sync_to_async(user_can_subscribe_delivery_task)(user, task):
            await self.close(code=4403)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        payload = await database_sync_to_async(build_delivery_payload)(task)
        await self.send(text_data=json.dumps(payload))

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def delivery_task_update(self, event):
        await self.send(text_data=json.dumps(event['payload']))

    @database_sync_to_async
    def _fetch_task(self):
        try:
            return VolunteerTask.objects.select_related(
                'volunteer',
                'donation_request',
                'donation_request__created_by',
                'donation_offer',
                'donation_offer__donor',
                'donation',
                'donation__donor',
                'donation__donation_request',
                'donation__donation_request__created_by',
            ).get(pk=self.task_id)
        except VolunteerTask.DoesNotExist:
            return None
