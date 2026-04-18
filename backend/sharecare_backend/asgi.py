"""
ASGI config for sharecare_backend project.
HTTP → Django; WebSocket → Channels (JWT auth via query string).
"""
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sharecare_backend.settings')

from django.core.asgi import get_asgi_application
from django.conf import settings

# Initialize Django before importing apps (middleware/routing need settings)
base_asgi_app = get_asgi_application()

# Serve static files (e.g. Django admin CSS) when running via Daphne in dev.
# In production this should be handled by a proper web server / CDN.
if settings.DEBUG:
    try:
        from django.contrib.staticfiles.handlers import ASGIStaticFilesHandler
        django_asgi_app = ASGIStaticFilesHandler(base_asgi_app)
    except Exception:  # pragma: no cover - safety net if handler missing
        django_asgi_app = base_asgi_app
else:
    django_asgi_app = base_asgi_app

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator

from django.urls import re_path
from apps.messages.middleware import JWTAuthMiddleware
from apps.messages.routing import websocket_urlpatterns
from apps.donations.consumers import CampaignProgressConsumer
from apps.volunteers.consumers import DeliveryTaskTrackingConsumer

websocket_urlpatterns = list(websocket_urlpatterns) + [
    re_path(r'ws/campaigns/(?P<campaign_id>\d+)/$', CampaignProgressConsumer.as_asgi()),
    re_path(
        r'ws/delivery-tasks/(?P<task_id>\d+)/$',
        DeliveryTaskTrackingConsumer.as_asgi(),
    ),
]

application = ProtocolTypeRouter({
    'http': django_asgi_app,
    'websocket': AllowedHostsOriginValidator(
        JWTAuthMiddleware(
            URLRouter(websocket_urlpatterns),
        ),
    ),
})
