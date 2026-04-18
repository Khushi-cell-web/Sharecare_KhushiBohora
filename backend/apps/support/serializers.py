"""Support ticket serializers."""
from rest_framework import serializers
from .models import SupportTicket


class SupportTicketSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = SupportTicket
        fields = [
            'id', 'subject', 'message', 'category', 'category_display',
            'status', 'status_display', 'admin_reply',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'status', 'admin_reply', 'created_at', 'updated_at']


class SupportTicketCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTicket
        fields = ['subject', 'message', 'category']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
