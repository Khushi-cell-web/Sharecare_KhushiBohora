from django.urls import path

from . import views

app_name = 'chat'

urlpatterns = [
    path('partners/', views.chat_partners, name='chat-partners'),
    path('room/', views.chat_room, name='chat-room'),
    path('rooms/', views.chat_rooms, name='chat-rooms'),
    path('messages/<int:room_id>/', views.chat_messages, name='chat-messages'),
    path('send/', views.chat_send, name='chat-send'),
    path('read/', views.chat_read, name='chat-read'),
]

