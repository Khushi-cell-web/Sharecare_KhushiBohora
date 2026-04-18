"""Profile URLs: /api/profile/ - alias for auth/me and activity."""
from django.urls import path

from . import views

app_name = 'users_profile'

urlpatterns = [
    path('', views.MeView.as_view(), name='me'),
    path('activity/', views.activity_history, name='activity-history'),
]
