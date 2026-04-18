from django.urls import path

from . import views

app_name = 'messages'

urlpatterns = [
    path('conversations/', views.ConversationListView.as_view(), name='conversation-list'),
    path('conversations/create/', views.ConversationCreateView.as_view(), name='conversation-create'),
    path('conversations/<int:pk>/', views.ConversationDetailView.as_view(), name='conversation-detail'),
    path(
        'conversations/<int:conversation_id>/messages/',
        views.MessageListCreateView.as_view(),
        name='message-list-create',
    ),
    path(
        'conversations/<int:conversation_id>/mark-read/',
        views.mark_messages_read,
        name='mark-read',
    ),
]
