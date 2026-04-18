"""Life donations API: blood registration (90-day rule) and organ pledge."""
from datetime import timedelta

from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.donations.blood_utils import (
    BLOOD_COOLDOWN_DAYS,
    BLOOD_COOLDOWN_MESSAGE,
    can_user_donate_blood,
    record_blood_donation,
)
from apps.donations.models import BloodDonationRecord

from .models import BloodDonation, OrganPledge, UserProfile
from .serializers_life import (
    BloodDonationRegistrationSerializer,
    OrganPledgeReadSerializer,
    OrganPledgeSerializer,
)


def _get_profile(user):
    profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def blood_status(request):
    """Eligibility, last donation, next available date, last registered blood group."""
    ok, msg = can_user_donate_blood(request.user)
    last_rec = (
        BloodDonationRecord.objects.filter(user=request.user)
        .order_by('-recorded_at')
        .first()
    )
    last_bd = (
        BloodDonation.objects.filter(user=request.user)
        .order_by('-created_at')
        .first()
    )
    next_available = None
    if last_rec and not ok:
        next_available = (
            last_rec.recorded_at + timedelta(days=BLOOD_COOLDOWN_DAYS)
        ).date().isoformat()

    return Response(
        {
            'eligible': ok,
            'message': msg if not ok else None,
            'last_donation': last_rec.recorded_at.isoformat() if last_rec else None,
            'next_available_date': next_available,
            'blood_group': last_bd.blood_group if last_bd else None,
        }
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_blood(request):
    """
    Submit blood donation registration after form validation.
    Enforces 90-day server-side cooldown (BloodDonationRecord).
    """
    ser = BloodDonationRegistrationSerializer(data=request.data)
    if not ser.is_valid():
        return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)

    ok, msg = can_user_donate_blood(request.user)
    if not ok:
        last_rec = (
            BloodDonationRecord.objects.filter(user=request.user)
            .order_by('-recorded_at')
            .first()
        )
        next_eligible = None
        if last_rec:
            next_eligible = (
                last_rec.recorded_at + timedelta(days=BLOOD_COOLDOWN_DAYS)
            ).date().isoformat()
        if next_eligible:
            detail = (
                'You are not eligible to donate blood yet. '
                f'You can donate after {next_eligible}.'
            )
        else:
            detail = msg or BLOOD_COOLDOWN_MESSAGE
        return Response(
            {
                'detail': detail.strip(),
                'next_eligible_date': next_eligible,
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    data = ser.validated_data
    BloodDonation.objects.create(
        user=request.user,
        full_name=data['full_name'],
        age=data['age'],
        blood_group=data['blood_group'],
        contact_number=data['contact_number'],
        first_time_donor=data['first_time_donor'],
        last_donation_declared=data.get('last_donation_date'),
        health_no_illness=data['health_no_illness'],
        health_not_on_medication=data['health_not_on_medication'],
        health_meets_weight_requirements=data['health_meets_weight_requirements'],
        consent_information_correct=data['consent_information_correct'],
    )
    record_blood_donation(request.user, 'life_donation_form')
    profile = _get_profile(request.user)
    profile.last_blood_donation = timezone.now()
    profile.save(update_fields=['last_blood_donation'])

    next_after = (timezone.now() + timedelta(days=BLOOD_COOLDOWN_DAYS)).date().isoformat()
    return Response(
        {
            'message': 'Blood donation registered successfully. Thank you for saving lives.',
            'blood_group': data['blood_group'],
            'last_donation': profile.last_blood_donation.isoformat(),
            'next_eligible_date': next_after,
        },
        status=status.HTTP_201_CREATED,
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def organ_status(request):
    pledge = OrganPledge.objects.filter(user=request.user).first()
    profile = _get_profile(request.user)
    return Response(
        {
            'is_pledged': pledge is not None,
            'pledge': OrganPledgeReadSerializer(pledge).data if pledge else None,
            'details': profile.organ_pledge_details or None,
        }
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_organ_pledge(request):
    ser = OrganPledgeSerializer(data=request.data)
    if not ser.is_valid():
        return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)

    d = ser.validated_data
    OrganPledge.objects.update_or_create(
        user=request.user,
        defaults={
            'full_name': d['full_name'],
            'date_of_birth': d['date_of_birth'],
            'gender': d['gender'],
            'address': d['address'],
            'contact_number': d['contact_number'],
            'email': d['email'],
            'organs': d['organs'],
            'emergency_contact_name': d['emergency_contact_name'],
            'emergency_contact_phone': d['emergency_contact_phone'],
            'medical_notes': d.get('medical_notes') or '',
            'consent_organ_donation': d['consent_organ_donation'],
        },
    )
    profile = _get_profile(request.user)
    profile.is_organ_pledged = True
    profile.organ_pledge_details = ', '.join(d['organs'])
    profile.save(update_fields=['is_organ_pledged', 'organ_pledge_details'])

    return Response(
        {
            'message': 'Thank you for your organ donation pledge.',
            'is_pledged': True,
            'organs': d['organs'],
        },
        status=status.HTTP_201_CREATED,
    )
