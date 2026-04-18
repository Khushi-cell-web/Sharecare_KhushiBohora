from django.urls import path

from . import views

app_name = 'support'

urlpatterns = [
    path('tickets/', views.SupportTicketCreateView.as_view(), name='ticket-create'),
    path('tickets/my/', views.SupportTicketListView.as_view(), name='my-tickets'),
    path('faq/', views.faq_list, name='faq'),
]
