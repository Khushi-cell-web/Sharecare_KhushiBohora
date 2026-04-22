from django import template

from apps.adminpanel.models import Report, UserSuspension
from apps.donations.models import DonationOffer, DonationRequest
from apps.notifications.models import DeviceToken, Notification
from apps.support.models import SupportTicket
from apps.users.models import User, UserProfile
from apps.volunteers.models import VolunteerTask

register = template.Library()


@register.simple_tag
def admin_dashboard_summary():
    return {
        'users_total': User.objects.count(),
        'pending_verifications': UserProfile.objects.filter(verification_status='pending').count(),
        'verified_organizations': UserProfile.objects.filter(verification_status='verified').count(),
        'donation_requests_total': DonationRequest.objects.count(),
        'donation_offers_total': DonationOffer.objects.count(),
        'volunteer_tasks_total': VolunteerTask.objects.count(),
        'reports_pending': Report.objects.filter(status='pending').count(),
        'support_tickets_total': SupportTicket.objects.count(),
        'notifications_total': Notification.objects.count(),
        'active_suspensions': UserSuspension.objects.filter(is_active=True).count(),
        'device_tokens_total': DeviceToken.objects.count(),
    }


@register.simple_tag
def admin_pending_verifications(limit=6):
    return list(
        UserProfile.objects.select_related('user')
        .filter(verification_status='pending')
        .order_by('-updated_at')[:limit]
    )


@register.simple_tag
def admin_dashboard_shortcuts():
    return [
        {
            'title': 'User Verification',
            'subtitle': 'Approve or reject NGO and hospital profiles.',
            'url': 'admin:users_userprofile_changelist',
            'query': '?verification_status__exact=pending',
        },
        {
            'title': 'Users',
            'subtitle': 'Open the user list page.',
            'url': 'admin:users_user_changelist',
            'query': '',
        },
        {
            'title': 'Reports',
            'subtitle': 'Moderation and escalation cases.',
            'url': 'admin:adminpanel_report_changelist',
            'query': '',
        },
        {
            'title': 'Donation Requests',
            'subtitle': 'All donation requests on their own page.',
            'url': 'admin:donations_donationrequest_changelist',
            'query': '',
        },
        {
            'title': 'Volunteer Tasks',
            'subtitle': 'Task management and status tracking.',
            'url': 'admin:volunteers_volunteertask_changelist',
            'query': '',
        },
        {
            'title': 'Support Tickets',
            'subtitle': 'User support records and replies.',
            'url': 'admin:support_supportticket_changelist',
            'query': '',
        },
    ]
