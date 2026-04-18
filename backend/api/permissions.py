from rest_framework import permissions


class IsNGO(permissions.BasePermission):
    """Only users with NGO/Hospital role."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) == 'ngo'


class IsDonor(permissions.BasePermission):
    """Only users with Donor role."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) == 'donor'


class IsVolunteer(permissions.BasePermission):
    """Only users with Volunteer role."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) == 'volunteer'


class IsAdminOrReadOnly(permissions.BasePermission):
    """Admin can do anything; others read-only."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return request.user.is_authenticated
        return (
            request.user.is_authenticated
            and getattr(request.user, 'role', None) == 'admin'
        )


def has_role(user, *roles):
    """Check if user has one of the given roles."""
    if not user.is_authenticated:
        return False
    return getattr(user, 'role', None) in roles
