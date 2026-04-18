"""
URL configuration for sharecare_backend project.
RESTful API grouped by module.
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """API root - health check / info."""
    return Response({
        'app': 'ShareCare API',
        'version': '1.0',
        'status': 'ok',
        'modules': ['auth', 'donations', 'volunteers', 'notifications', 'admin', 'payments', 'messages', 'support'],
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Health check: DB connection and optional service status. GET /api/health/"""
    import os
    from django.db import connection

    db_ok = False
    db_error = None
    try:
        connection.ensure_connection()
        db_ok = True
    except Exception as e:
        db_error = str(e)

    stripe_configured = bool(os.getenv('STRIPE_SECRET_KEY', '').strip())
    try:
        from apps.payments.esewa_service import is_esewa_configured
        esewa_configured = is_esewa_configured()
    except Exception:
        esewa_configured = False

    status_code = 200 if db_ok else 503
    return Response({
        'status': 'ok' if db_ok else 'degraded',
        'database': 'connected' if db_ok else 'disconnected',
        'database_error': db_error,
        'stripe_configured': stripe_configured,
        'esewa_configured': esewa_configured,
    }, status=status_code)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', api_root),
    path('api/health/', health_check),
    path('api/auth/', include('apps.users.urls')),  # register, login, me, forgot/reset password
    path('api/', include('apps.users.urls_life_donations')),
    path('api/profile/', include('apps.users.urls_profile')),  # alias for me (profile)
    path('api/requests/', include('apps.donations.urls_requests')),
    path('api/campaigns/', include('apps.donations.urls_campaigns')),  # list, create, detail, update, close
    path('api/donations/', include('apps.donations.urls')),
    path('api/impact/', include('apps.donations.urls_impact')),
    path('api/volunteers/', include('apps.volunteers.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/admin/', include('apps.adminpanel.urls')),
    path('api/payments/', include('apps.payments.urls')),
    path('api/messages/', include('apps.messages.urls')),
    path('api/chat/', include('apps.messages.urls_chat')),
    path('api/support/', include('apps.support.urls')),
]
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

