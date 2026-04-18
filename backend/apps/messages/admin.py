from django.contrib import admin
from .models import Conversation, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user1', 'user2', 'created_at', 'updated_at')
    list_filter = ('created_at',)
    search_fields = ('user1__username', 'user2__username')


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'sender', 'text_preview', 'created_at', 'read_at')
    list_filter = ('created_at',)
    search_fields = ('text', 'sender__username')

    def text_preview(self, obj):
        return (obj.text or '')[:50] + ('...' if len(obj.text or '') > 50 else '')

    text_preview.short_description = 'Text'
