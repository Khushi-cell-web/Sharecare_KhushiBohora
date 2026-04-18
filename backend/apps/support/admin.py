from django.contrib import admin
from .models import SupportTicket


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'subject', 'category', 'status', 'created_at')
    list_filter = ('status', 'category')
    search_fields = ('subject', 'message', 'user__username')
