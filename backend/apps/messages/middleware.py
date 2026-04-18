"""JWT auth for WebSocket: read token from query string and set scope['user']."""
from urllib.parse import parse_qs

from asgiref.sync import sync_to_async
from django.contrib.auth.models import AnonymousUser


@sync_to_async
def get_user_from_token(token_string):
    """Validate JWT and return User or None."""
    if not token_string:
        return AnonymousUser()
    try:
        from rest_framework_simplejwt.tokens import AccessToken
        from apps.users.models import User
        access = AccessToken(token_string)
        user_id = access.get('user_id')
        user = User.objects.get(pk=user_id)
        return user
    except Exception:
        return AnonymousUser()


class JWTAuthMiddleware:
    """
    Custom middleware that reads JWT from query string (?token=...) and sets scope['user'].
    Use in ASGI as: JWTAuthMiddleware(URLRouter(...))
    """

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope['type'] == 'websocket':
            query_string = scope.get('query_string', b'')
            if isinstance(query_string, bytes):
                query_string = query_string.decode('utf-8')
            params = parse_qs(query_string)
            token_list = params.get('token', params.get('access', []))
            token = token_list[0] if token_list else None
            scope['user'] = await get_user_from_token(token)
        return await self.app(scope, receive, send)
