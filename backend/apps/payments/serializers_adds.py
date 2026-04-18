from rest_framework import serializers

class EsewaMobileConfirmSerializer(serializers.Serializer):
    product_id = serializers.CharField(required=True)
    ref_id = serializers.CharField(required=True)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
