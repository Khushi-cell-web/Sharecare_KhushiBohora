"""URLs for Requests API: /api/requests/ (list, create, detail, update, close)."""
from django.urls import path

from . import views

app_name = 'donations_requests'

urlpatterns = [
    path('', views.DonationRequestListCreateView.as_view(), name='request-list-create'),
    path('<int:pk>/', views.DonationRequestDetailView.as_view(), name='request-detail'),
    path('<int:pk>/close/', views.DonationRequestCloseView.as_view(), name='request-close'),
]
