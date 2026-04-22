from django.apps import AppConfig
from django.contrib import admin


class AdminpanelConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.adminpanel'
    verbose_name = 'Admin Panel'

    def ready(self):
        from apps.adminpanel.models import Report, UserSuspension
        from apps.donations.models import DonationOffer, DonationRequest
        from apps.notifications.models import DeviceToken, Notification
        from apps.support.models import SupportTicket
        from apps.users.models import User, UserProfile
        from apps.volunteers.models import VolunteerTask

        original_each_context = admin.site.each_context

        def each_context_with_dashboard(request):
            context = original_each_context(request)
            context.update(
                {
                    'sc_admin_summary': {
                        'users_total': User.objects.count(),
                        'pending_verifications': UserProfile.objects.filter(
                            verification_status='pending'
                        ).count(),
                        'verified_organizations': UserProfile.objects.filter(
                            verification_status='verified'
                        ).count(),
                        'donation_requests_total': DonationRequest.objects.count(),
                        'donation_offers_total': DonationOffer.objects.count(),
                        'volunteer_tasks_total': VolunteerTask.objects.count(),
                        'reports_pending': Report.objects.filter(status='pending').count(),
                        'support_tickets_total': SupportTicket.objects.count(),
                        'notifications_total': Notification.objects.count(),
                        'active_suspensions': UserSuspension.objects.filter(
                            is_active=True
                        ).count(),
                        'device_tokens_total': DeviceToken.objects.count(),
                    },
                    'sc_admin_pending_profiles': list(
                        UserProfile.objects.select_related('user')
                        .filter(verification_status='pending')
                        .order_by('-updated_at')[:6]
                    ),
                    'sc_admin_shortcuts': [
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
                    ],
                }
            )
            return context

        admin.site.each_context = each_context_with_dashboard
