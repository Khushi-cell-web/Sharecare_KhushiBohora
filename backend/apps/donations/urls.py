from django.urls import path

from . import views
from apps.payments import views as payment_views

app_name = 'donations'

urlpatterns = [
    path('blood-eligibility/', views.blood_donation_eligibility, name='blood-eligibility'),
    path('donations/', views.DonationCreateListView.as_view(), name='donation-create-list'),
    path('donations/pending/', views.NGOPendingDonationListView.as_view(), name='ngo-pending-donations'),
    path('donations/accepted/', views.NGOAcceptedDonationListView.as_view(), name='ngo-accepted-donations'),
    path('donations/<int:pk>/accept/', views.DonationAcceptView.as_view(), name='donation-accept'),
    path('requests/', views.DonationRequestListCreateView.as_view(), name='request-list-create'),
    path('requests/<int:pk>/', views.DonationRequestDetailView.as_view(), name='request-detail'),
    path('requests/<int:pk>/progress/', views.campaign_progress, name='campaign-progress'),
    path('requests/<int:pk>/donations/', views.campaign_donations_list, name='campaign-donations'),
    path('requests/<int:pk>/receipt/', views.donation_receipt, name='request-receipt'),
    path('requests/my/', views.my_requests, name='my-requests'),
    path('requests/received-offers/', views.ReceivedDonationsView.as_view(), name='received-offers'),
    path('requests/<int:request_id>/offers/', views.DonationOffersForRequestView.as_view(), name='offers-for-request'),
    path('requests/<int:request_id>/updates/', views.CampaignUpdateListCreateView.as_view(), name='campaign-updates'),
    path('offers/', views.DonationOfferCreateView.as_view(), name='offer-create'),
    path('offers/my/', views.DonationOfferListView.as_view(), name='my-offers'),
    path('offers/<int:pk>/accept-reject/', views.DonationOfferAcceptRejectView.as_view(), name='offer-accept-reject'),
    path('matches/my/', views.DonationMatchListView.as_view(), name='match-my'),
    path('matches/<int:pk>/respond/', views.DonationMatchRespondView.as_view(), name='match-respond'),
    path('matches/auto-create/', views.auto_create_matches, name='match-auto-create'),
    path('pay/', payment_views.donation_pay, name='pay'),
    path('history/', payment_views.DonationTransactionListView.as_view(), name='history'),
    path('stats/', views.donation_stats, name='stats'),
    path('recommendations/', views.RecommendationView.as_view(), name='recommendations'),
]
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'p2p-donations', views.UserItemDonationViewSet, basename='p2p-donations')

urlpatterns += router.urls
