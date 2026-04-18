"""Volunteer task serializers."""
from rest_framework import serializers

from .models import Redemption, Reward, VolunteerTask


class VolunteerTaskSerializer(serializers.ModelSerializer):
    volunteer_username = serializers.CharField(source='volunteer.username', read_only=True)
    donation_request_title = serializers.SerializerMethodField()
    donation_request_category = serializers.SerializerMethodField()
    donation_request_category_display = serializers.SerializerMethodField()
    task_status_display = serializers.CharField(source='get_task_status_display', read_only=True)
    donor_username = serializers.SerializerMethodField()
    donor_id = serializers.SerializerMethodField()
    request_creator_id = serializers.SerializerMethodField()
    delivery_latitude = serializers.SerializerMethodField()
    delivery_longitude = serializers.SerializerMethodField()
    donation_request_urgency = serializers.SerializerMethodField()
    is_urgent_delivery = serializers.SerializerMethodField()
    delivery_points = serializers.SerializerMethodField()

    class Meta:
        model = VolunteerTask
        fields = [
            'id', 'volunteer', 'volunteer_username', 'donation_request', 'donation',
            'donation_request_title',
            'donation_request_category', 'donation_request_category_display',
            'donation_request_urgency', 'is_urgent_delivery', 'delivery_points',
            'donation_offer', 'donor_username', 'donor_id', 'request_creator_id',
            'pickup_location', 'delivery_location',
            'pickup_latitude', 'pickup_longitude',
            'delivery_latitude', 'delivery_longitude', 'task_status', 'task_status_display',
            'points_awarded', 'points_earned',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'volunteer',
            'points_awarded',
            'points_earned',
            'created_at',
            'updated_at',
        ]

    def get_donation_request_title(self, obj):
        if obj.donation_request_id:
            return obj.donation_request.title
        if obj.donation_id:
            d = obj.donation
            head = (d.description or '').strip().split('\n')[0][:120]
            return head or d.get_category_display() or 'Standalone donation'
        return ''

    def get_donation_request_category(self, obj):
        if obj.donation_request_id:
            return obj.donation_request.category
        if obj.donation_id:
            return obj.donation.category
        return None

    def get_donation_request_category_display(self, obj):
        if obj.donation_request_id:
            return obj.donation_request.get_category_display()
        if obj.donation_id:
            return obj.donation.get_category_display()
        return None

    def get_donation_request_urgency(self, obj):
        if obj.donation_request_id and obj.donation_request:
            return obj.donation_request.urgency
        return None

    def get_is_urgent_delivery(self, obj):
        return self.get_donation_request_urgency(obj) == 'High'

    def get_delivery_points(self, obj):
        return obj.completion_points()

    def get_donor_username(self, obj):
        if obj.donation_offer_id and obj.donation_offer:
            u = obj.donation_offer.donor
            return u.get_full_name() or u.username
        if obj.donation_id and obj.donation:
            u = obj.donation.donor
            return u.get_full_name() or u.username
        return None

    def get_donor_id(self, obj):
        if obj.donation_offer_id and obj.donation_offer:
            return obj.donation_offer.donor_id
        if obj.donation_id and obj.donation:
            return obj.donation.donor_id
        return None

    def get_request_creator_id(self, obj):
        if obj.donation_request_id and obj.donation_request:
            return obj.donation_request.created_by_id
        return None

    def get_delivery_latitude(self, obj):
        if obj.delivery_latitude is not None:
            return obj.delivery_latitude
        if obj.donation_request_id and obj.donation_request.latitude is not None:
            return obj.donation_request.latitude
        if obj.donation_id and obj.donation.delivery_latitude is not None:
            return obj.donation.delivery_latitude
        return None

    def get_delivery_longitude(self, obj):
        if obj.delivery_longitude is not None:
            return obj.delivery_longitude
        if obj.donation_request_id and obj.donation_request.longitude is not None:
            return obj.donation_request.longitude
        if obj.donation_id and obj.donation.delivery_longitude is not None:
            return obj.donation.delivery_longitude
        return None


class RewardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Reward
        fields = ['id', 'name', 'required_points', 'is_active']


class RedemptionSerializer(serializers.ModelSerializer):
    reward_name = serializers.CharField(source='reward.name', read_only=True)
    reward_required_points = serializers.IntegerField(source='reward.required_points', read_only=True)

    class Meta:
        model = Redemption
        fields = [
            'id',
            'reward',
            'reward_name',
            'reward_required_points',
            'points_spent',
            'date_redeemed',
        ]


class RedeemRewardSerializer(serializers.Serializer):
    reward_id = serializers.IntegerField(min_value=1)
