from django.contrib import admin
from .models import Report, UserSuspension


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['id', 'reporter', 'reported_user', 'report_type', 'status', 'created_at']
    list_filter = ['report_type', 'status']


@admin.register(UserSuspension)
class UserSuspensionAdmin(admin.ModelAdmin):
    list_display = ['user', 'suspended_by', 'suspended_at', 'expires_at', 'is_active']
    list_filter = ['is_active']
