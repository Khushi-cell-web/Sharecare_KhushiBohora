"""Serializers for Life Donations (blood registration, organ pledge)."""
from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from .models import BloodDonation, OrganPledge

ALLOWED_ORGANS = frozenset(
    {'Heart', 'Kidney', 'Liver', 'Lungs', 'Pancreas', 'Eyes', 'Skin', 'Tissue', 'Intestines'}
)


class BloodDonationRegistrationSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255, trim_whitespace=True)
    age = serializers.IntegerField(min_value=18, max_value=120)
    blood_group = serializers.ChoiceField(choices=BloodDonation.BLOOD_GROUP_CHOICES)
    contact_number = serializers.CharField(max_length=32, trim_whitespace=True)
    first_time_donor = serializers.BooleanField()
    last_donation_date = serializers.DateField(required=False, allow_null=True)
    health_no_illness = serializers.BooleanField()
    health_not_on_medication = serializers.BooleanField()
    health_meets_weight_requirements = serializers.BooleanField()
    consent_information_correct = serializers.BooleanField()

    def validate_contact_number(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('Contact number is required.')
        return value.strip()

    def validate(self, attrs):
        if not attrs.get('consent_information_correct'):
            raise serializers.ValidationError(
                {'consent_information_correct': 'You must confirm that the information is correct.'}
            )
        if not (
            attrs.get('health_no_illness')
            and attrs.get('health_not_on_medication')
            and attrs.get('health_meets_weight_requirements')
        ):
            raise serializers.ValidationError(
                'All health declarations must be accepted to proceed.'
            )
        if attrs.get('first_time_donor'):
            attrs['last_donation_date'] = None
        else:
            ld = attrs.get('last_donation_date')
            if ld is None:
                raise serializers.ValidationError(
                    {'last_donation_date': 'Required unless you are a first-time donor.'}
                )
            today = timezone.now().date()
            days_since = (today - ld).days
            if days_since < 90:
                next_eligible = ld + timedelta(days=90)
                raise serializers.ValidationError(
                    {
                        'last_donation_date': (
                            'You are not eligible to donate blood yet based on this date. '
                            f'You can donate after {next_eligible.isoformat()}.'
                        )
                    }
                )
        return attrs


class OrganPledgeSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255, trim_whitespace=True)
    date_of_birth = serializers.DateField()
    gender = serializers.ChoiceField(
        choices=['male', 'female', 'other', 'prefer_not_say']
    )
    address = serializers.CharField(max_length=1000, trim_whitespace=True)
    contact_number = serializers.CharField(max_length=32, trim_whitespace=True)
    email = serializers.EmailField()
    organs = serializers.ListField(
        child=serializers.CharField(max_length=64),
        min_length=1,
    )
    emergency_contact_name = serializers.CharField(max_length=255, trim_whitespace=True)
    emergency_contact_phone = serializers.CharField(max_length=32, trim_whitespace=True)
    medical_notes = serializers.CharField(
        required=False, allow_blank=True, max_length=2000, default=''
    )
    consent_organ_donation = serializers.BooleanField()

    def validate_organs(self, value):
        invalid = [o for o in value if o not in ALLOWED_ORGANS]
        if invalid:
            raise serializers.ValidationError(
                f'Invalid organ selection: {", ".join(invalid)}. Allowed: {", ".join(sorted(ALLOWED_ORGANS))}.'
            )
        return list(dict.fromkeys(value))

    def validate(self, attrs):
        if not attrs.get('consent_organ_donation'):
            raise serializers.ValidationError(
                {
                    'consent_organ_donation': (
                        'You must agree to voluntarily donate organs and understand the terms.'
                    )
                }
            )
        return attrs


class OrganPledgeReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrganPledge
        fields = [
            'full_name',
            'date_of_birth',
            'gender',
            'address',
            'contact_number',
            'email',
            'organs',
            'emergency_contact_name',
            'emergency_contact_phone',
            'medical_notes',
            'created_at',
            'updated_at',
        ]
