from django.urls import path

from . import views_impact

urlpatterns = [
    path('create/', views_impact.impact_create, name='impact-create'),
    path('campaign/<int:campaign_id>/', views_impact.impact_list_campaign, name='impact-list-campaign'),
]
