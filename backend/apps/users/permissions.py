"""Role-based permissions for ShareCare."""
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


class IsDonorOrVolunteer(permissions.BasePermission):
    """Donor or Volunteer - e.g. can create donation offers (matchmaking)."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) in ('donor', 'volunteer')


class IsVolunteer(permissions.BasePermission):
    """Only users with Volunteer role."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) == 'volunteer'


class IsAdmin(permissions.BasePermission):
    """Only users with Admin role."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return getattr(request.user, 'role', None) == 'admin'


class IsNGOOrAdmin(permissions.BasePermission):
    """NGO or Admin (e.g. create donation requests)."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        role = getattr(request.user, 'role', None)
        return role in ('ngo', 'admin')


class IsVerifiedNGOOrAdmin(permissions.BasePermission):
    """Only verified NGO/Hospital or Admin (e.g. create donation requests)."""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        role = getattr(request.user, 'role', None)
        if role == 'admin':
            return True
        if role != 'ngo':
            return False
        try:
            profile = request.user.profile
            return profile.verification_status == 'verified'
        except Exception:
            return False


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
