from django.contrib import admin
from .models import Redemption, Reward, VolunteerTask, VolunteerTaskDecline


@admin.register(VolunteerTask)
class VolunteerTaskAdmin(admin.ModelAdmin):
    list_display = [
        'volunteer',
        'donation_request',
        'task_status',
        'points_awarded',
        'points_earned',
        'pickup_location',
        'delivery_location',
        'created_at',
    ]
    list_filter = ['task_status']


@admin.register(VolunteerTaskDecline)
class VolunteerTaskDeclineAdmin(admin.ModelAdmin):
    list_display = ['volunteer', 'volunteer_task', 'created_at']


@admin.register(Reward)
class RewardAdmin(admin.ModelAdmin):
    list_display = ['name', 'required_points', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['name']


@admin.register(Redemption)
class RedemptionAdmin(admin.ModelAdmin):
    list_display = ['user', 'reward', 'points_spent', 'date_redeemed']
    list_filter = ['reward']
    search_fields = ['user__username', 'reward__name']
