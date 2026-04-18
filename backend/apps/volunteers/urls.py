from django.urls import path

from . import views

app_name = 'volunteers'

urlpatterns = [
    path('available-requests/', views.VolunteerAvailableRequestsView.as_view(), name='available-requests'),
    path('pending-tasks/', views.VolunteerPendingTasksView.as_view(), name='pending-tasks'),
    path('points/', views.VolunteerPointsView.as_view(), name='points'),
    path('rewards/', views.RewardListView.as_view(), name='rewards'),
    path('rewards/redeem/', views.RedeemRewardView.as_view(), name='rewards-redeem'),
    path('rewards/redemptions/', views.RedemptionHistoryView.as_view(), name='rewards-redemptions'),
    path('tasks/', views.VolunteerTaskAcceptView.as_view(), name='task-accept'),
    path('tasks/my/', views.VolunteerTaskListView.as_view(), name='my-tasks'),
    path('tasks/<int:pk>/claim/', views.volunteer_task_claim, name='task-claim'),
    path('tasks/<int:pk>/decline/', views.volunteer_task_decline, name='task-decline'),
    path('tasks/<int:pk>/', views.VolunteerTaskDetailView.as_view(), name='task-detail'),
]
