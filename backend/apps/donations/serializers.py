"""Donation request and offer serializers."""
from rest_framework import serializers
from django.utils import timezone

from .blood_utils import can_user_donate_blood
from .models import CampaignUpdate, Donation, DonationOffer, DonationRequest, ImpactUpdate, DonationMatch


class DonationRequestSerializer(serializers.ModelSerializer):
    """List/create/update donation requests. Organization is read-only (from creator)."""
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    organization = serializers.CharField(source='created_by.organization', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    percent_funded = serializers.FloatField(read_only=True)
    creator_full_name = serializers.SerializerMethodField()
    creator_profile_location = serializers.SerializerMethodField()
    requested_by_label = serializers.SerializerMethodField()

    class Meta:
        model = DonationRequest
        fields = [
            'id', 'title', 'description', 'image', 'gallery_images', 'category', 'category_display',
              'quantity_needed', 'remaining_quantity', 'urgency', 'location', 'latitude', 'longitude', 'status', 'status_display',
            'goal_amount', 'raised_amount', 'percent_funded',
            'extra_data',
            'created_by', 'created_by_username', 'organization',
            'creator_full_name', 'creator_profile_location', 'requested_by_label',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'raised_amount', 'remaining_quantity']
    def validate_quantity_needed(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('Quantity must be greater than 0.')
        return value

    def validate_urgency(self, value):
        valid = [c[0] for c in DonationRequest.URGENCY_CHOICES]
        if value not in valid:
            raise serializers.ValidationError(
                f'Urgency must be one of: {", ".join(valid)}.'
            )
        return value

    def get_creator_full_name(self, obj):
        u = obj.created_by
        if not u:
            return ''
        name = (u.get_full_name() or '').strip()
        return name or u.username

    def get_creator_profile_location(self, obj):
        try:
            loc = getattr(obj.created_by.profile, 'location', None) or ''
            return loc
        except Exception:
            return ''

    def get_requested_by_label(self, obj):
        org = (getattr(obj.created_by, 'organization', None) or '').strip()
        if org:
            return f'Requested by {org}'
        return f'Requested by {self.get_creator_full_name(obj)}'


class DonationRequestStatusSerializer(serializers.ModelSerializer):
    """NGO: update request status only (open / matched / fulfilled / closed)."""
    status = serializers.ChoiceField(choices=DonationRequest.STATUS_CHOICES)

    class Meta:
        model = DonationRequest
        fields = ['id', 'status']
        read_only_fields = ['id']


class DonationOfferSerializer(serializers.ModelSerializer):
    donor_username = serializers.CharField(source='donor.username', read_only=True)
    donation_request_title = serializers.CharField(source='donation_request.title', read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    fulfillment_type_display = serializers.CharField(source='get_fulfillment_type_display', read_only=True)
    delivery_task_id = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = DonationOffer
        fields = [
            'id', 'donor', 'donor_username', 'donation_request', 'donation_request_title',
            'type', 'type_display', 'quantity', 'message', 'status', 'status_display',
            'fulfillment_type', 'fulfillment_type_display',
            'pickup_location', 'pickup_latitude', 'pickup_longitude',
            'delivery_task_id',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['donor', 'created_at', 'updated_at']

    def validate(self, attrs):
        request = self.context.get('request')
        data = super().validate(attrs)
        dr = attrs.get('donation_request')
        if dr is None and self.instance is not None:
            dr = self.instance.donation_request
        dr_pk = None
        if dr is not None:
            dr_pk = dr.pk if hasattr(dr, 'pk') else dr
        if dr_pk and request and request.user.is_authenticated:
            dro = DonationRequest.objects.filter(pk=dr_pk).only('category').first()
            if dro and dro.category == 'blood':
                ok, msg = can_user_donate_blood(request.user)
                if not ok:
                    raise serializers.ValidationError({'non_field_errors': [msg]})

        offer_type = attrs.get('type') or getattr(self.instance, 'type', None)
        fulfillment = attrs.get('fulfillment_type') or getattr(
            self.instance, 'fulfillment_type', 'volunteer_pickup'
        )
        pickup = (attrs.get('pickup_location') or getattr(self.instance, 'pickup_location', '') or '').strip()
        if not pickup and self.instance is not None:
            pickup = (getattr(self.instance.donation_request, 'location', None) or '').strip()
        if not pickup and offer_type == 'material' and fulfillment == 'volunteer_pickup':
            dr = attrs.get('donation_request')
            if dr is not None:
                if hasattr(dr, 'location'):
                    pickup = (dr.location or '').strip()
                else:
                    loc = (
                        DonationRequest.objects.filter(pk=dr)
                        .values_list('location', flat=True)
                        .first()
                    )
                    pickup = (loc or '').strip()
        if offer_type == 'material' and fulfillment == 'volunteer_pickup':
            if not pickup:
                raise serializers.ValidationError(
                    {'pickup_location': 'Pickup location is required when requesting a volunteer pickup.'}
                )
        return data

    def get_delivery_task_id(self, obj):
        task = obj.volunteer_tasks_for_offer.order_by('-id').first()
        return task.id if task else None


class ImpactUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ImpactUpdate
        fields = ['id', 'campaign', 'title', 'description', 'images', 'people_helped', 'created_at']
        read_only_fields = ['created_at']
        extra_kwargs = {'campaign': {'required': False}}


class CampaignUpdateSerializer(serializers.ModelSerializer):
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = CampaignUpdate
        fields = ['id', 'donation_request', 'title', 'content', 'created_by', 'created_by_username', 'created_at']
        read_only_fields = ['created_by', 'created_at']


class DonationSerializer(serializers.ModelSerializer):
    """Standalone or linked donation (record)."""
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    type_display = serializers.CharField(source='get_donation_type_display', read_only=True)
    status_display = serializers.SerializerMethodField()
    fulfillment_type_display = serializers.CharField(source='get_fulfillment_type_display', read_only=True)
    delivery_task_id = serializers.SerializerMethodField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_near_expiry = serializers.BooleanField(read_only=True)
    accepted_by_ngo_username = serializers.CharField(source='accepted_by_ngo.username', read_only=True)
    assigned_volunteer_username = serializers.CharField(source='assigned_volunteer.username', read_only=True)

    class Meta:
        model = Donation
        fields = [
            'id', 'donor', 'donation_request', 'category', 'category_display',
            'donation_type', 'type_display', 'quantity', 'description', 'status', 'status_display',
            'fulfillment_type', 'fulfillment_type_display',
            'pickup_location', 'pickup_latitude', 'pickup_longitude',
            'delivery_location', 'delivery_latitude', 'delivery_longitude',
            'expiry_date', 'valid_until', 'is_expired', 'is_near_expiry',
            'accepted_by_ngo', 'accepted_by_ngo_username', 'assigned_volunteer',
            'assigned_volunteer_username',
            'delivery_task_id',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['donor', 'created_at', 'updated_at']

    def get_status_display(self, obj):
        label_map = {
            'pending': 'Pending NGO review',
            'confirmed': 'Accepted by NGO',
            'assigned': 'Volunteer assigned',
            'picked_up': 'Picked up',
            'in_transit': 'In transit',
            'completed': 'Delivered',
            'expired': 'Expired',
        }
        return label_map.get(obj.status, obj.get_status_display())

    def get_delivery_task_id(self, obj):
        task = obj.volunteer_tasks.order_by('-id').first()
        return task.id if task else None


class DonationCreateSerializer(serializers.ModelSerializer):
    """POST: create donation (donation_request optional)."""

    class Meta:
        model = Donation
        fields = [
            'donation_request', 'category', 'donation_type', 'quantity', 'description',
            'fulfillment_type',
            'pickup_location', 'pickup_latitude', 'pickup_longitude',
            'delivery_location', 'delivery_latitude', 'delivery_longitude',
            'expiry_date', 'valid_until',
        ]

    def validate_category(self, value):
        valid = [c[0] for c in DonationRequest.CATEGORY_CHOICES]
        if value not in valid:
            raise serializers.ValidationError(f'Category must be one of: {", ".join(valid)}.')
        return value

    def validate(self, attrs):
        request = self.context.get('request')
        if attrs.get('category') == 'blood' and request and request.user.is_authenticated:
            ok, msg = can_user_donate_blood(request.user)
            if not ok:
                raise serializers.ValidationError({'non_field_errors': [msg]})

        category = attrs.get('category')
        now = timezone.now()
        if category == 'food':
            expiry_date = attrs.get('expiry_date')
            valid_until = attrs.get('valid_until') or expiry_date

            if expiry_date is None:
                raise serializers.ValidationError(
                    {'expiry_date': 'Expiry date is required for food donations.'}
                )
            if expiry_date <= now:
                raise serializers.ValidationError(
                    {'expiry_date': 'Expiry date must be in the future.'}
                )
            if valid_until is None:
                raise serializers.ValidationError(
                    {'valid_until': 'Valid until is required for food donations.'}
                )
            if valid_until <= now:
                raise serializers.ValidationError(
                    {'valid_until': 'Valid until must be in the future.'}
                )
            if valid_until < expiry_date:
                raise serializers.ValidationError(
                    {'valid_until': 'Valid until must be on or after expiry date.'}
                )

            attrs['valid_until'] = valid_until
        else:
            attrs['expiry_date'] = None
            attrs['valid_until'] = None

        if attrs.get('fulfillment_type') == 'volunteer_pickup':
            if attrs.get('donation_type') != 'material':
                raise serializers.ValidationError(
                    {'fulfillment_type': 'Volunteer delivery applies to material donations only.'}
                )
            if not (attrs.get('pickup_location') or '').strip():
                raise serializers.ValidationError(
                    {'pickup_location': 'Pickup location is required for volunteer delivery.'}
                )
            # Allow standalone donations to not specify delivery_location (matched later)
            if not attrs.get('donation_request') and not (attrs.get('delivery_location') or '').strip():
                 attrs['delivery_location'] = 'To be determined (Pending NGO Match)'
        return attrs

    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['donor'] = user
        dr = validated_data.get('donation_request')
        if dr is None:
            if validated_data.get('category') == 'blood':
                validated_data['status'] = 'completed'
            else:
                validated_data.setdefault('status', 'pending')
        else:
            validated_data.setdefault('status', 'pending')
        return super().create(validated_data)


class DonationMatchSerializer(serializers.ModelSerializer):
    donor_username = serializers.CharField(source='donor.username', read_only=True)
    receiver_username = serializers.CharField(source='receiver.username', read_only=True)

    category = serializers.CharField(source='donation_request.category', read_only=True)
    urgency = serializers.CharField(source='donation_request.urgency', read_only=True)
    request_location = serializers.CharField(source='donation_request.location', read_only=True)
    request_title = serializers.CharField(source='donation_request.title', read_only=True)

    my_role = serializers.SerializerMethodField()
    donation_type = serializers.SerializerMethodField()
    quantity = serializers.SerializerMethodField()
    pickup_location = serializers.SerializerMethodField()
    expiry_date = serializers.SerializerMethodField()
    valid_until = serializers.SerializerMethodField()
    is_near_expiry = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()

    stage = serializers.SerializerMethodField()
    task_status = serializers.SerializerMethodField()

    class Meta:
        model = DonationMatch
        fields = [
            'id',
            'status',
            'donor_decision',
            'receiver_decision',
            'distance_km',
            'category',
            'urgency',
            'request_title',
            'request_location',
            'donor_username',
            'receiver_username',
            'my_role',
            'donation_type',
            'quantity',
            'pickup_location',
            'expiry_date',
            'valid_until',
            'is_near_expiry',
            'is_expired',
            'stage',
            'task_status',
            'created_at',
            'updated_at',
        ]

    def get_my_role(self, obj: DonationMatch) -> str:
        viewer = self.context.get('viewer')
        if not viewer:
            return 'unknown'
        if obj.donor_id == getattr(viewer, 'id', None):
            return 'donor'
        if obj.receiver_id == getattr(viewer, 'id', None):
            return 'receiver'
        return 'unknown'

    def get_donation_type(self, obj: DonationMatch) -> str:
        if obj.donation is not None:
            return obj.donation.donation_type
        if obj.donation_offer is not None:
            return obj.donation_offer.type
        return 'unknown'

    def get_quantity(self, obj: DonationMatch) -> int:
        if obj.donation is not None:
            return obj.donation.quantity
        if obj.donation_offer is not None:
            return obj.donation_offer.quantity
        return 0

    def get_pickup_location(self, obj: DonationMatch) -> str:
        if obj.donation is not None and (obj.donation.pickup_location or '').strip():
            return obj.donation.pickup_location
        if obj.donation_offer is not None and (obj.donation_offer.pickup_location or '').strip():
            return obj.donation_offer.pickup_location
        return obj.donation_request.location

    def get_expiry_date(self, obj: DonationMatch):
        if obj.donation is None:
            return None
        return obj.donation.expiry_date

    def get_valid_until(self, obj: DonationMatch):
        if obj.donation is None:
            return None
        return obj.donation.valid_until

    def get_is_near_expiry(self, obj: DonationMatch) -> bool:
        if obj.donation is None:
            return False
        return obj.donation.is_near_expiry

    def get_is_expired(self, obj: DonationMatch) -> bool:
        if obj.donation is None:
            return False
        return obj.donation.is_expired

    def get_task_status(self, obj: DonationMatch) -> str:
        if obj.donation_offer_id is None:
            return ''
        try:
            from apps.volunteers.models import VolunteerTask

            task = (
                VolunteerTask.objects.filter(donation_offer_id=obj.donation_offer_id)
                .order_by('-id')
                .first()
            )
            return task.task_status if task else ''
        except Exception:
            return ''

    def get_stage(self, obj: DonationMatch) -> str:
        if obj.status == 'rejected':
            return 'rejected'
        if obj.status != 'accepted':
            return 'pending'

        task_status = self.get_task_status(obj)
        if not task_status:
            return 'matched'
        if task_status == 'delivered':
            return 'delivered'
        if task_status in ('pending_volunteer', 'assigned', 'picked', 'in_transit'):
            return 'in_progress'
        return 'in_progress'
from .models import UserItemDonation, DonationStatusHistory

class DonationStatusHistorySerializer(serializers.ModelSerializer):
    updated_by_username = serializers.CharField(source='updated_by.username', read_only=True)
    
    class Meta:
        model = DonationStatusHistory
        fields = ['id', 'status', 'updated_by', 'updated_by_username', 'timestamp']

class UserItemDonationSerializer(serializers.ModelSerializer):
    donor_username = serializers.CharField(source='donor.username', read_only=True)
    receiver_username = serializers.CharField(source='receiver.username', read_only=True)
    status_history = DonationStatusHistorySerializer(many=True, read_only=True)
    
    class Meta:
        model = UserItemDonation
        fields = [
            'id', 'title', 'description', 'category', 'image', 'location',
            'donor', 'donor_username', 'receiver', 'receiver_username',
            'status', 'is_active', 'created_at', 'updated_at', 'status_history'
        ]
        read_only_fields = ['donor', 'receiver', 'status', 'is_active', 'status_history']
