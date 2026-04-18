from django.urls import path

from . import views_media

urlpatterns = [
    path('upload-media/', views_media.CampaignUploadMediaView.as_view(), name='upload-media'),
]
