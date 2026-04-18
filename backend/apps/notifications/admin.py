from django.contrib import admin
from .models import Notification, DeviceToken


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ['user', 'token_preview', 'created_at']

    def token_preview(self, obj):
        return f'{obj.token[:20]}...' if len(obj.token) > 20 else obj.token
    token_preview.short_description = 'Token'


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read']
