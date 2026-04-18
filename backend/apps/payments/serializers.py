"""Payment transaction serializers."""
from rest_framework import serializers

from .models import DonationTransaction, PaymentTransaction


class CreateIntentSerializer(serializers.Serializer):
    donation_request_id = serializers.IntegerField(required=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.50)
    currency = serializers.CharField(default='USD', max_length=3)


class ConfirmPaymentSerializer(serializers.Serializer):
    payment_intent_id = serializers.CharField(required=True, max_length=255)
    donation_request_id = serializers.IntegerField(required=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.50)
    donation_type = serializers.ChoiceField(
        choices=[('one_time', 'One-time'), ('recurring', 'Recurring')],
        default='one_time',
    )


class PaymentTransactionSerializer(serializers.ModelSerializer):
    campaign_title = serializers.CharField(
        source='donation_request.title', read_only=True, default=None
    )

    class Meta:
        model = PaymentTransaction
        fields = [
            'id', 'user', 'donation_request', 'campaign_title',
            'amount', 'currency', 'gateway', 'transaction_id',
            'status', 'created_at',
        ]
        read_only_fields = fields


class DonationTransactionSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    type_display = serializers.CharField(source='get_donation_type_display', read_only=True)
    donation_request_title = serializers.CharField(
        source='donation_request.title', read_only=True, default=None
    )

    class Meta:
        model = DonationTransaction
        fields = [
            'id', 'user', 'donation_request', 'donation_request_title',
            'donation_offer', 'amount', 'currency', 'donation_type', 'type_display',
            'status', 'status_display', 'payment_reference', 'gateway_reference',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class EsewaMobileConfirmSerializer(serializers.Serializer):
    product_id = serializers.CharField(required=True)
    ref_id = serializers.CharField(required=True)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class EsewaInitSerializer(serializers.Serializer):
    donation_request_id = serializers.IntegerField(required=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=0, min_value=1)
    donation_type = serializers.ChoiceField(
        choices=[('one_time', 'One-time'), ('recurring', 'Recurring')],
        default='one_time',
    )


class DonationPaySerializer(serializers.Serializer):
    donation_request_id = serializers.IntegerField(required=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0.01)
    donation_type = serializers.ChoiceField(
        choices=[('one_time', 'One-time'), ('recurring', 'Recurring')],
        default='one_time',
    )
    currency = serializers.CharField(default='USD', max_length=3)
    payment_reference = serializers.CharField(required=False, allow_blank=True)
