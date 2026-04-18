from django.urls import path

from . import views

app_name = 'payments'

urlpatterns = [
    path('create-intent/', views.payment_create_intent, name='create-intent'),
    path('confirm/', views.stripe_confirm_payment, name='stripe-confirm'),
    path('esewa-init/', views.esewa_init, name='esewa-init'),
    path('esewa-form/', views.esewa_form, name='esewa-form'),
    path('esewa-callback/', views.esewa_callback, name='esewa-callback'),
    path('esewa-failure/', views.esewa_failure, name='esewa-failure'),
    path('esewa-mobile/init/', views.esewa_mobile_init, name='esewa-mobile-init'),
    path('esewa-mobile/confirm/', views.esewa_mobile_confirm, name='esewa-mobile-confirm'),
    path('history/', views.PaymentHistoryListView.as_view(), name='payment-history'),
    path('transactions/', views.DonationTransactionListView.as_view(), name='transaction-list'),
    path('transactions/<int:pk>/receipt/', views.transaction_receipt, name='transaction-receipt'),
    path('confirm-offer/', views.payment_confirm, name='payment-confirm-offer'),
]
