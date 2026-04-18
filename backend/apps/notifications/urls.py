from django.urls import path

from . import views

app_name = 'notifications'

urlpatterns = [
    path('', views.NotificationListView.as_view(), name='list'),
    path('register-device/', views.register_device, name='register-device'),
    path('mark-read/', views.mark_notification_read, name='mark-all-read'),
    path('<int:pk>/mark-read/', views.mark_notification_read, name='mark-read'),
]
