"""Donations app: donation requests, offers, campaign updates, receipts, recommendations."""
from datetime import timedelta

from django.core.mail import send_mail
from django.conf import settings
from django.db.models import Count, Sum, Q
from django.db import models
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from django.http import HttpResponse
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from io import BytesIO

from apps.users.permissions import IsNGO, IsVerifiedNGOOrAdmin
from apps.payments.models import DonationTransaction

from .delivery_service import create_pending_volunteer_task_for_offer
from .models import CampaignUpdate, Donation, DonationMatch, DonationOffer, DonationRequest, ImpactUpdate


def _send_request_fulfilled_email(donation_request):
    """Send email to NGO when request is fulfilled (quantity met)."""
    ngo = donation_request.created_by
    email = getattr(ngo, 'email', None)
    if not email or not str(email).strip() or '@' not in str(email):
        return
    subject = f'ShareCare: Your request "{donation_request.title}" is fulfilled'
    message = (
        f'Hello {ngo.get_full_name() or ngo.username},\n\n'
        f'Your donation request "{donation_request.title}" has been fully fulfilled.\n'
        f'The required quantity ({donation_request.quantity_needed}) has been met through accepted offers.\n\n'
        f'Thank you for using ShareCare.\n'
    )
    try:
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=True,
        )
    except Exception:
        pass
from .blood_utils import BLOOD_COOLDOWN_MESSAGE, can_user_donate_blood
from .serializers import (
    CampaignUpdateSerializer,
    DonationCreateSerializer,
    DonationMatchSerializer,
    DonationOfferSerializer,
    DonationRequestSerializer,
    DonationSerializer,
)


class DonationRequestListCreateView(generics.ListCreateAPIView):
    """List donation requests (GET, authenticated). Create request (POST, NGO or Admin)."""
    serializer_class = DonationRequestSerializer

    def get_queryset(self):
        qs = DonationRequest.objects.select_related('created_by').order_by('-created_at')
        # Filters: category, urgency, status
        category = self.request.query_params.get('category')
        if category:
            qs = qs.filter(category=category)
        urgency = self.request.query_params.get('urgency')
        if urgency:
            qs = qs.filter(urgency=urgency)
        status_filter = self.request.query_params.get('status')
        if status_filter and status_filter.lower() == 'all':
            pass
        elif status_filter:
            qs = qs.filter(status=status_filter)
        else:
            qs = qs.filter(status='open')
        return qs

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsVerifiedNGOOrAdmin()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        dr = serializer.save(created_by=self.request.user)
        try:
            from apps.notifications.tasks import notify_campaign_created
            notify_campaign_created(dr)
        except Exception:
            pass


class DonationRequestDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete donation request. NGO owner only for PUT/DELETE."""
    queryset = DonationRequest.objects.select_related('created_by')
    serializer_class = DonationRequestSerializer

    def get_permissions(self):
        if self.request.method in ('PATCH', 'PUT', 'DELETE'):
            return [IsAuthenticated(), IsNGO()]
        return [IsAuthenticated()]

    def get_queryset(self):
        qs = DonationRequest.objects.select_related('created_by')
        if self.request.method in ('PATCH', 'PUT', 'DELETE'):
            return qs.filter(created_by=self.request.user)
        return qs

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
        instance.delete()


class DonationRequestCloseView(generics.GenericAPIView):
    """PATCH /api/requests/<id>/close/ — close request. NGO owner only."""
    permission_classes = [IsAuthenticated, IsNGO]
    queryset = DonationRequest.objects.select_related('created_by')

    def get_queryset(self):
        return DonationRequest.objects.filter(created_by=self.request.user)

    def patch(self, request, pk=None):
        obj = self.get_object()
        obj.status = 'closed'
        obj.save(update_fields=['status', 'updated_at'])
        serializer = DonationRequestSerializer(obj)
        return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_requests(request):
    """Donation requests created by current user (NGO)."""
    qs = DonationRequest.objects.filter(created_by=request.user).order_by('-created_at')
    serializer = DonationRequestSerializer(qs, many=True)
    return Response(serializer.data)


class ReceivedDonationsView(generics.ListAPIView):
    """NGO: list accepted offers (received donations) for current user's requests."""
    permission_classes = [IsAuthenticated, IsNGO]
    serializer_class = DonationOfferSerializer

    def get_queryset(self):
        return DonationOffer.objects.filter(
            donation_request__created_by=self.request.user,
            status='accepted',
        ).select_related('donor', 'donation_request').order_by('-created_at')


class DonationOfferCreateView(generics.CreateAPIView):
    """Donor offers a donation for a request."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationOfferSerializer

    def get_permissions(self):
        from apps.users.permissions import IsDonorOrVolunteer
        return [IsAuthenticated(), IsDonorOrVolunteer()]

    def perform_create(self, serializer):
        from django.db import transaction
        from rest_framework.exceptions import ValidationError
        from apps.notifications.models import Notification
        from apps.donations.models import DonationOffer
        
        # Prevent duplicate offers before create.
        req = serializer.validated_data.get('donation_request')
        if DonationOffer.objects.filter(donor=self.request.user, donation_request=req).exists():
            raise ValidationError({'detail': 'You have already made an offer for this donation request.'})
            
        with transaction.atomic():
            req = serializer.validated_data.get('donation_request')
            offer_qty = serializer.validated_data.get('quantity', 1)
            
            # Row lock keeps quantity updates atomic.
            req = req.__class__.objects.select_for_update().get(pk=req.pk)
            
            # Backfill legacy rows with null remaining quantity.
            if req.remaining_quantity is None:
                req.remaining_quantity = req.quantity_needed
            
            if req.remaining_quantity < offer_qty:
                raise ValidationError({'quantity': f'Cannot donate more than the remaining quantity ({req.remaining_quantity}).'})
            
            offer = serializer.save(donor=self.request.user)
            req.remaining_quantity -= offer_qty
            if req.remaining_quantity == 0:
                req.status = 'completed'
            else:
                req.status = 'partially_fulfilled'
            req.save()
            
            # Send donor notification.
            Notification.objects.create(
                user=offer.donor,
                notification_type='donation_made',
                title='Donation Successful',
                message=f'{offer_qty} items donated successfully.',
                target_id=req.id,
                target_type='donation_request'
            )
            
            if req.created_by is not None:
                if req.remaining_quantity == 0:
                    msg_for_ngo = 'Your donation request has been completely fulfilled!'
                else:
                    msg_for_ngo = f'Your donation request has been partially fulfilled ({req.remaining_quantity} remaining).'

                Notification.objects.create(
                    user=req.created_by,
                    notification_type='offer_received',
                    title='Donation Request Update',
                    message=msg_for_ngo,
                    target_id=req.id,
                    target_type='donation_request'
                )


class DonationOfferListView(generics.ListAPIView):
    """List donation offers (e.g. my offers)."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationOfferSerializer

    def get_queryset(self):
        return DonationOffer.objects.filter(donor=self.request.user).select_related(
            'donation_request', 'donor'
        ).order_by('-created_at')


class DonationOffersForRequestView(generics.ListAPIView):
    """NGO: list offers for a donation request they created."""
    permission_classes = [IsAuthenticated, IsNGO]
    serializer_class = DonationOfferSerializer

    def get_queryset(self):
        request_id = self.kwargs.get('request_id')
        return DonationOffer.objects.filter(
            donation_request_id=request_id,
            donation_request__created_by=self.request.user,
        ).select_related('donor', 'donation_request').order_by('-created_at')


class DonationOfferAcceptRejectView(generics.UpdateAPIView):
    """NGO: accept or reject an offer (donation lifecycle: open -> matched -> fulfilled)."""
    permission_classes = [IsAuthenticated, IsNGO]
    serializer_class = DonationOfferSerializer
    http_method_names = ['patch', 'put']

    def get_queryset(self):
        return DonationOffer.objects.filter(
            donation_request__created_by=self.request.user,
            status='pending',
        ).select_related('donation_request')

    def perform_update(self, serializer):
        from django.db.models import Sum

        offer = self.get_object()
        new_status = self.request.data.get('status')
        if new_status not in ('accepted', 'rejected'):
            from rest_framework import serializers
            raise serializers.ValidationError({'status': 'Must be "accepted" or "rejected".'})
        serializer.save(status=new_status)
        if new_status == 'accepted':
            offer.refresh_from_db()
            dr = offer.donation_request
            dr.status = 'matched'
            dr.save(update_fields=['status', 'updated_at'])
            create_pending_volunteer_task_for_offer(offer)

            # Check if total accepted quantity meets quantity_needed -> mark fulfilled & send email
            total_accepted = DonationOffer.objects.filter(
                donation_request=dr,
                status='accepted',
            ).aggregate(total=Sum('quantity'))['total'] or 0
            if total_accepted >= dr.quantity_needed:
                dr.status = 'fulfilled'
                dr.save(update_fields=['status', 'updated_at'])
                _send_request_fulfilled_email(dr)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def campaign_progress(request, pk):
    """GET /api/donations/requests/<id>/progress/ - Campaign fundraising progress."""
    try:
        dr = DonationRequest.objects.get(pk=pk)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)
    return Response({
        'campaign_id': dr.id,
        'title': dr.title,
        'goal_amount': float(dr.goal_amount),
        'raised_amount': float(dr.raised_amount),
        'total_donated': float(dr.raised_amount),
        'percent_funded': dr.percent_funded,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def donation_stats(request):
    """
    GET /api/donations/stats/ - Real-time analytics for dashboard charts.
    Returns: donations_by_week, category_distribution, request_status,
    weekly_donors, lives_touched (people helped across all impact updates).
    """
    from apps.payments.models import DonationTransaction
    now = timezone.now()
    categories = ['food', 'clothes', 'funds', 'blood', 'organ', 'other']

    # Donations by week (last 5 weeks)
    donations_by_week = []
    for i in range(5):
        week_start = now - timedelta(weeks=i + 1)
        week_end = now - timedelta(weeks=i)
        count = DonationTransaction.objects.filter(
            created_at__gte=week_start,
            created_at__lt=week_end,
            status__in=('confirmed', 'completed'),
        ).count()
        donations_by_week.append(count)
    donations_by_week.reverse()

    # Category distribution (donations by campaign category, percent)
    category_counts = DonationTransaction.objects.filter(
        status__in=('confirmed', 'completed'),
        donation_request__isnull=False,
        donation_request__category__in=categories,
    ).values('donation_request__category').annotate(count=Count('id'))
    total_donations = sum(c['count'] for c in category_counts)
    category_distribution = []
    for c in categories:
        cnt = next(
            (x['count'] for x in category_counts if x.get('donation_request__category') == c),
            0,
        )
        pct = round((cnt / total_donations * 100) if total_donations else 0)
        category_distribution.append({'label': c.title(), 'value': pct, 'count': cnt})

    # Request status: open, matched, fulfilled
    status_counts = DonationRequest.objects.values('status').annotate(count=Count('id'))
    status_map = {s['status']: s['count'] for s in status_counts}
    request_status = [
        {'label': 'Open', 'value': status_map.get('open', 0)},
        {'label': 'Partial', 'value': status_map.get('matched', 0)},
        {'label': 'Fulfilled', 'value': status_map.get('fulfilled', 0)},
    ]

    # Weekly donors (unique donors per week, last 5 weeks)
    weekly_donors = []
    for i in range(5):
        week_start = now - timedelta(weeks=i + 1)
        week_end = now - timedelta(weeks=i)
        count = DonationTransaction.objects.filter(
            created_at__gte=week_start,
            created_at__lt=week_end,
            status__in=('confirmed', 'completed'),
        ).values('user').distinct().count()
        weekly_donors.append(count)
    weekly_donors.reverse()

    # Total lives touched: sum of people_helped from all impact updates + completed acts
    lives_touched_impact = ImpactUpdate.objects.aggregate(total=Sum('people_helped'))['total'] or 0
    completed_tx = DonationTransaction.objects.filter(status__in=('confirmed', 'completed')).count()
    completed_offers = DonationOffer.objects.filter(status__in=('completed', 'accepted')).count()
    completed_donations = Donation.objects.filter(status='completed').count()
    lives_touched = lives_touched_impact + completed_tx + completed_offers + completed_donations

    return Response({
        'donations_by_week': donations_by_week,
        'category_distribution': category_distribution,
        'request_status': request_status,
        'weekly_donors': weekly_donors,
        'lives_touched': lives_touched,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def campaign_donations_list(request, pk):
    """GET /api/donations/requests/<id>/donations/ - List donations for a campaign."""
    from apps.payments.models import DonationTransaction
    from apps.payments.serializers import DonationTransactionSerializer

    try:
        DonationRequest.objects.get(pk=pk)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    qs = DonationTransaction.objects.filter(
        donation_request_id=pk,
        status__in=('completed', 'confirmed'),
    ).select_related('user', 'donation_request').order_by('-created_at')
    serializer = DonationTransactionSerializer(qs, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def donation_receipt(request, pk):
    """GET /api/donations/requests/<id>/receipt/ - Generate PDF receipt for a donation transaction."""
    from apps.payments.models import DonationTransaction

    # Find transaction for this request and user
    txn = DonationTransaction.objects.filter(
        donation_request_id=pk,
        user=request.user,
        status__in=('completed', 'confirmed'),
    ).order_by('-created_at').first()

    if not txn:
        return Response({'detail': 'No completed donation found for this campaign.'}, status=status.HTTP_404_NOT_FOUND)

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
    styles = getSampleStyleSheet()
    story = []

    story.append(Paragraph('ShareCare Donation Receipt', styles['Title']))
    story.append(Spacer(1, 0.3 * inch))
    story.append(Paragraph(f'Receipt #: {txn.id}', styles['Normal']))
    story.append(Paragraph(f'Date: {txn.created_at.strftime("%Y-%m-%d %H:%M")}', styles['Normal']))
    story.append(Paragraph(f'Donor: {request.user.username}', styles['Normal']))
    story.append(Paragraph(f'Campaign: {txn.donation_request.title if txn.donation_request else "N/A"}', styles['Normal']))
    story.append(Paragraph(f'Amount: {txn.amount} {txn.currency}', styles['Normal']))
    story.append(Paragraph(f'Type: {txn.get_donation_type_display()}', styles['Normal']))
    story.append(Paragraph(f'Status: {txn.get_status_display()}', styles['Normal']))
    story.append(Spacer(1, 0.5 * inch))
    story.append(Paragraph('Thank you for your donation!', styles['Normal']))

    doc.build(story)
    buffer.seek(0)
    response = HttpResponse(buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="sharecare_receipt_{txn.id}.pdf"'
    return response


class RecommendationView(generics.GenericAPIView):
    """GET /api/donations/recommendations/ - Smart matchmaking: rank open campaigns
    by the donor's past category preferences, location proximity, and urgency."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationRequestSerializer

    def get(self, request, *args, **kwargs):
        from collections import Counter
        from apps.payments.models import DonationTransaction

        user = request.user
        qs = DonationRequest.objects.filter(status='open').select_related('created_by')

        past_cats = list(
            DonationOffer.objects.filter(donor=user)
            .values_list('donation_request__category', flat=True)
        )
        past_cats += list(
            DonationTransaction.objects.filter(user=user)
            .values_list('donation_request__category', flat=True)
        )
        cat_counts = Counter(c for c in past_cats if c)
        top_cats = [c for c, _ in cat_counts.most_common()]

        profile = getattr(user, 'profile', None)
        user_location = ''
        if profile:
            user_location = (getattr(profile, 'location', '') or '').lower().strip()

        urgency_weight = {'High': 3, 'Medium': 2, 'Low': 1}

        scored = []
        for dr in qs:
            score = 0.0
            if dr.category in top_cats:
                rank = top_cats.index(dr.category)
                score += max(10 - rank * 2, 2)
            score += urgency_weight.get(dr.urgency, 1)
            if user_location and user_location in (dr.location or '').lower():
                score += 5
            scored.append((score, dr))

        scored.sort(key=lambda x: (-x[0], x[1].created_at))
        top_requests = [dr for _, dr in scored[:20]]

        if not top_requests:
            from django.db.models import Case, When, IntegerField
            top_requests = list(
                qs.annotate(
                    urgency_order=Case(
                        When(urgency='High', then=3),
                        When(urgency='Medium', then=2),
                        When(urgency='Low', then=1),
                        default=0,
                        output_field=IntegerField(),
                    )
                ).order_by('-urgency_order', '-created_at')[:20]
            )

        serializer = self.get_serializer(top_requests, many=True)
        return Response(serializer.data)


class CampaignUpdateListCreateView(generics.ListCreateAPIView):
    """List/create campaign updates. NGO owner only for create."""
    serializer_class = CampaignUpdateSerializer

    def get_queryset(self):
        request_id = self.kwargs.get('request_id')
        return CampaignUpdate.objects.filter(
            donation_request_id=request_id
        ).select_related('created_by').order_by('-created_at')

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), IsNGO()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        from apps.users.permissions import IsNGO
        dr = DonationRequest.objects.get(pk=self.kwargs['request_id'])
        if dr.created_by != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only campaign owner can post updates.')
        serializer.save(donation_request=dr, created_by=self.request.user)


class DonationCreateListView(generics.ListCreateAPIView):
    """
    POST: create a donation (standalone or linked to donation_request).
    GET: list current user's donations.
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return DonationCreateSerializer
        return DonationSerializer

    def get_permissions(self):
        from apps.users.permissions import IsDonorOrVolunteer

        if self.request.method == 'POST':
            return [IsAuthenticated(), IsDonorOrVolunteer()]
        return [IsAuthenticated()]

    def get_queryset(self):
        Donation.expire_due_donations()
        return Donation.objects.filter(donor=self.request.user).select_related(
            'donation_request', 'donor'
        ).order_by('-created_at')

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['request'] = self.request
        return ctx

    def perform_create(self, serializer):
        serializer.save()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def blood_donation_eligibility(request):
    """GET /api/donations/blood-eligibility/ — 90-day rule check for current user."""
    ok, msg = can_user_donate_blood(request.user)
    return Response({
        'eligible': ok,
        'message': None if ok else (msg or BLOOD_COOLDOWN_MESSAGE),
    })


class DonationMatchListView(generics.ListAPIView):
    """GET /api/donations/matches/my/ - List matchmaking cards for current user."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationMatchSerializer

    def get_queryset(self):
        user = self.request.user
        Donation.expire_due_donations()
        return (
            DonationMatch.objects.filter(donor=user) | DonationMatch.objects.filter(receiver=user)
        ).select_related(
            'donor',
            'receiver',
            'donation',
            'donation_request',
            'donation_offer',
        ).exclude(
            donation__status='expired'
        ).order_by('-created_at')

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx['viewer'] = self.request.user
        return ctx


class DonationMatchRespondView(generics.UpdateAPIView):
    """
    PATCH /api/donations/matches/<id>/respond/
    Body: { "response": "accepted" | "rejected" }
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DonationMatchSerializer
    http_method_names = ['patch', 'put']

    def get_queryset(self):
        user = self.request.user
        return DonationMatch.objects.filter(donor=user) | DonationMatch.objects.filter(receiver=user)

    def update(self, request, *args, **kwargs):
        from rest_framework.exceptions import ValidationError, PermissionDenied

        match: DonationMatch = self.get_object()
        response = (request.data.get('response') or '').strip().lower()
        if response not in ('accepted', 'rejected'):
            raise ValidationError({'response': 'Must be "accepted" or "rejected".'})

        user = request.user
        is_donor = match.donor_id == user.id
        is_receiver = match.receiver_id == user.id
        if not (is_donor or is_receiver):
            raise PermissionDenied('Not allowed.')

        if match.status == 'accepted' and response == 'rejected':
            raise ValidationError({'detail': 'This match is already accepted.'})

        if is_donor:
            match.donor_decision = response
        if is_receiver:
            match.receiver_decision = response

        if response == 'rejected':
            match.status = 'rejected'
        else:
            if match.donor_decision == 'accepted' and match.receiver_decision == 'accepted':
                match.status = 'accepted'

        # If there is an existing offer row, keep it in sync for NGO flow.
        if match.donation_offer_id and response == 'rejected':
            offer = match.donation_offer
            if offer and offer.status == 'pending':
                offer.status = 'rejected'
                offer.save(update_fields=['status'])

        match.save()

        # Convert only after both accept.
        if match.status == 'accepted':
            from .matchmaking_service import finalize_match_if_both_accepted

            finalize_match_if_both_accepted(match)

        serializer = self.get_serializer(match, context={'viewer': user})
        return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def auto_create_matches(request):
    """
    POST /api/donations/matches/auto-create/
    Body: { "donation_id": <int>, "donation_request_id": <int> }
    Either id is optional; at least one must be provided.
    """
    from rest_framework.exceptions import ValidationError, PermissionDenied

    donation_id = request.data.get('donation_id')
    donation_request_id = request.data.get('donation_request_id')

    if donation_id is None and donation_request_id is None:
        raise ValidationError({'detail': 'Provide donation_id or donation_request_id.'})

    Donation.expire_due_donations()

    created = 0
    if donation_id is not None:
        donation = Donation.objects.select_related('donor').filter(pk=donation_id).first()
        if not donation:
            raise ValidationError({'detail': 'Donation not found.'})
        # Donors can refresh matchmaking for their own donations.
        if donation.donor_id != request.user.id and not request.user.is_staff:
            raise PermissionDenied('Not allowed.')
        from .matchmaking_service import create_matches_for_donation

        created += create_matches_for_donation(donation)

    if donation_request_id is not None:
        dr = DonationRequest.objects.select_related('created_by').filter(pk=donation_request_id).first()
        if not dr:
            raise ValidationError({'detail': 'Donation request not found.'})
        # NGOs/Hospitals can refresh matchmaking for their own requests.
        if dr.created_by_id != request.user.id and not request.user.is_staff:
            raise PermissionDenied('Not allowed.')
        from .matchmaking_service import create_matches_for_request

        created += create_matches_for_request(dr)

    return Response({'created_matches': created})

from rest_framework import viewsets
from rest_framework.decorators import action
from .models import UserItemDonation, DonationStatusHistory
from .serializers import UserItemDonationSerializer
from apps.notifications.models import Notification
from apps.notifications.signals import notify 

def _log_status(donation, user, new_status):
    donation.status = new_status
    if new_status == 'COMPLETED':
        donation.is_active = False
    donation.save()
    DonationStatusHistory.objects.create(donation=donation, status=new_status, updated_by=user)

class UserItemDonationViewSet(viewsets.ModelViewSet):
    serializer_class = UserItemDonationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Users see active ones, plus and their own ones
        return UserItemDonation.objects.filter(models.Q(is_active=True) | models.Q(donor=self.request.user) | models.Q(receiver=self.request.user)).select_related('donor', 'receiver').prefetch_related('status_history', 'status_history__updated_by').order_by('-created_at')

    def perform_create(self, serializer):
        donation = serializer.save(donor=self.request.user, status='CREATED', is_active=True)
        DonationStatusHistory.objects.create(donation=donation, status='CREATED', updated_by=self.request.user)
        # Nearby notification hook can be added here.

    @action(detail=True, methods=['post'])
    def request_donation(self, request, pk=None):
        donation = self.get_object()
        if donation.status != 'CREATED' or not donation.is_active:
            return Response({'error': 'Donation is no longer available.'}, status=status.HTTP_400_BAD_REQUEST)
        if donation.donor == request.user:
            return Response({'error': 'You cannot request your own donation.'}, status=status.HTTP_400_BAD_REQUEST)
        
        donation.receiver = request.user
        _log_status(donation, request.user, 'REQUESTED')
        
        Notification.objects.create(
            notification_type='p2p_update',
            user=donation.donor,
            title='New Donation Request',
            message=f'{request.user.username} has requested your item: {donation.title}.',
        )
        return Response(UserItemDonationSerializer(donation).data)

    @action(detail=True, methods=['post'])
    def accept_request(self, request, pk=None):
        donation = self.get_object()
        if donation.donor != request.user:
            return Response({'error': 'Only the donor can accept the request.'}, status=status.HTTP_403_FORBIDDEN)
        if donation.status != 'REQUESTED':
            return Response({'error': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)
        
        _log_status(donation, request.user, 'ACCEPTED')
        
        Notification.objects.create(
            notification_type='p2p_update',
            user=donation.receiver,
            title='Request Accepted',
            message=f'Your request for {donation.title} has been accepted!',
        )
        return Response(UserItemDonationSerializer(donation).data)

    @action(detail=True, methods=['post'])
    def schedule_pickup(self, request, pk=None):
        donation = self.get_object()
        if request.user not in [donation.donor, donation.receiver]:
            return Response({'error': 'Not involved in this donation.'}, status=status.HTTP_403_FORBIDDEN)
        if donation.status != 'ACCEPTED':
            return Response({'error': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)
        
        _log_status(donation, request.user, 'SCHEDULED')
        
        target_user = donation.receiver if request.user == donation.donor else donation.donor
        Notification.objects.create(
            notification_type='p2p_update',
            user=target_user,
            title='Pickup Scheduled',
            message=f'Pickup for {donation.title} has been scheduled.',
        )
        return Response(UserItemDonationSerializer(donation).data)

    @action(detail=True, methods=['post'])
    def dispatch_item(self, request, pk=None):
        donation = self.get_object()
        if request.user not in [donation.donor, donation.receiver]:
            return Response({'error': 'Not involved in this donation.'}, status=status.HTTP_403_FORBIDDEN)
        if donation.status != 'SCHEDULED':
            return Response({'error': 'Invalid status.'}, status=status.HTTP_400_BAD_REQUEST)
        
        _log_status(donation, request.user, 'ON_THE_WAY')
        return Response(UserItemDonationSerializer(donation).data)

    @action(detail=True, methods=['post'])
    def complete_donation(self, request, pk=None):
        donation = self.get_object()
        if request.user != donation.receiver:
            return Response({'error': 'Only the receiver can confirm delivery.'}, status=status.HTTP_403_FORBIDDEN)
        if donation.status != 'ON_THE_WAY':
            return Response({'error': 'Item must be ON_THE_WAY to complete.'}, status=status.HTTP_400_BAD_REQUEST)
        
        _log_status(donation, request.user, 'COMPLETED')
        
        Notification.objects.create(
            notification_type='p2p_update',
            user=donation.donor,
            title='Donation Completed',
            message=f'{request.user.username} has received {donation.title}. Thank you!',
        )
        return Response(UserItemDonationSerializer(donation).data)
