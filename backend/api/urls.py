from django.urls import path

from rest_framework_simplejwt.views import TokenRefreshView

from . import views

app_name = 'api'

urlpatterns = [
    path('', views.api_root),
    # Auth
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/login/', views.LoginView.as_view(), name='login'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', views.MeView.as_view(), name='me'),
    # Donation requests
    path('requests/', views.DonationRequestListCreateView.as_view(), name='request-list-create'),
    path('requests/<int:pk>/', views.DonationRequestDetailView.as_view(), name='request-detail'),
    path('requests/my/', views.my_requests, name='my-requests'),
    # Donation offers (Donor)
    path('offers/', views.DonationOfferCreateView.as_view(), name='offer-create'),
    path('offers/my/', views.DonationOfferListView.as_view(), name='my-offers'),
    # Volunteer tasks
    path('tasks/', views.VolunteerTaskAcceptView.as_view(), name='task-accept'),
    path('tasks/my/', views.VolunteerTaskListView.as_view(), name='my-tasks'),
    path('tasks/<int:pk>/', views.VolunteerTaskDetailView.as_view(), name='task-detail'),
    # Notifications
    path('notifications/', views.NotificationListView.as_view(), name='notification-list'),
    path('notifications/<int:pk>/', views.NotificationDetailView.as_view(), name='notification-detail'),
    path('notifications/<int:pk>/read/', views.mark_notification_read, name='mark-notification-read'),
    path('notifications/mark-all-read/', views.mark_all_notifications_read, name='mark-all-read'),
    path('notifications/unread-count/', views.unread_notification_count, name='unread-count'),
]
