"""Mark /api/ requests as CSRF-exempt so Flutter web and JWT auth work."""
from django.utils.deprecation import MiddlewareMixin


class CsrfExemptApiMiddleware(MiddlewareMixin):
    """Skip CSRF check for API paths (JWT-only; no session cookies)."""

    def process_request(self, request):
        if request.path.startswith('/api/'):
            setattr(request, '_dont_enforce_csrf_checks', True)
