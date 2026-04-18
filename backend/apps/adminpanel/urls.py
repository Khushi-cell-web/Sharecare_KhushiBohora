from django.urls import path

from . import views

app_name = 'adminpanel'

urlpatterns = [
    # Reports
    path('reports/', views.ReportListCreateView.as_view(), name='report-list'),
    path('reports/<int:pk>/', views.ReportDetailView.as_view(), name='report-detail'),
    # Verification & NGO approval
    path('verification/', views.VerificationListView.as_view(), name='verification-list'),
    path('verification/<int:pk>/', views.VerificationDetailView.as_view(), name='verification-detail'),
    path('approve-ngo/<int:pk>/', views.approve_ngo, name='approve-ngo'),
    # Users & suspensions
    path('users/', views.AdminUserListView.as_view(), name='user-list'),
    path('users/<int:pk>/', views.AdminUserDetailView.as_view(), name='user-detail'),
    path('suspensions/', views.UserSuspensionListCreateView.as_view(), name='suspension-list-create'),
    path('users/<int:pk>/unsuspend/', views.unsuspend_user, name='user-unsuspend'),
    # Activity logs & dashboard
    path('logs/', views.ActivityLogListView.as_view(), name='activity-log-list'),
    path('dashboard/', views.admin_dashboard, name='dashboard'),
    path('analytics/', views.admin_analytics, name='analytics'),
]
