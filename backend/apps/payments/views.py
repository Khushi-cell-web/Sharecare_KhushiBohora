"""Payments app: pay, history, verification, receipt."""
import base64
import html
import json
from decimal import Decimal
from django.http import HttpResponse
from django.db import transaction
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.donations.models import DonationRequest
from apps.notifications.tasks import notify_donation_made, notify_campaign_goal_reached
from apps.notifications.models import Notification
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from .models import DonationTransaction, PaymentTransaction
from .esewa_service import (
    create_esewa_payment,
    verify_esewa_response,
    verify_esewa_mobile_transaction,
    is_esewa_configured,
)
from .serializers import (
    DonationTransactionSerializer,
    DonationPaySerializer,
    CreateIntentSerializer,
    ConfirmPaymentSerializer,
    EsewaInitSerializer,
    EsewaMobileConfirmSerializer,
    PaymentTransactionSerializer,
)
from .services import create_payment_intent, verify_payment_intent


def _apply_payment_to_request(donation_request: DonationRequest, amount: Decimal):
    goal_reached = False
    with transaction.atomic():
        donation_request = DonationRequest.objects.select_for_update().get(pk=donation_request.pk)
        donation_request.raised_amount = (donation_request.raised_amount or Decimal('0')) + amount
        update_fields = ['raised_amount', 'updated_at']
        if donation_request.goal_amount and donation_request.goal_amount > 0 and donation_request.raised_amount >= donation_request.goal_amount:
            goal_reached = True
            if donation_request.status != 'fulfilled':
                donation_request.status = 'fulfilled'
                update_fields.append('status')
        elif donation_request.status == 'open':
            donation_request.status = 'closed'
            update_fields.append('status')
        donation_request.save(update_fields=update_fields)
    return donation_request, goal_reached


class DonationTransactionListView(generics.ListAPIView):
    """GET /api/donations/history/ - List current user's donation transactions."""
    permission_classes = [IsAuthenticated]
    serializer_class = DonationTransactionSerializer

    def get_queryset(self):
        return DonationTransaction.objects.filter(user=self.request.user).select_related(
            'donation_request', 'donation_offer'
        ).order_by('-created_at')


class PaymentHistoryListView(generics.ListAPIView):
    """GET /api/payments/history/ - List current user's payment transactions (gateway)."""
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentTransactionSerializer

    def get_queryset(self):
        return PaymentTransaction.objects.filter(user=self.request.user).select_related(
            'donation_request'
        ).order_by('-created_at')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def payment_create_intent(request):
    """
    POST /api/payments/create-intent/
    Body: { donation_request_id, amount, currency? }
    Creates Stripe PaymentIntent, returns client_secret for frontend.
    """
    serializer = CreateIntentSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    donation_request_id = data['donation_request_id']
    amount = Decimal(str(data['amount']))
    currency = data.get('currency', 'USD')

    try:
        donation_request = DonationRequest.objects.get(pk=donation_request_id)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    try:
        result = create_payment_intent(
            amount=amount,
            currency=currency,
            metadata={
                'donation_request_id': str(donation_request_id),
                'user_id': str(request.user.id),
            },
        )
    except ValueError as e:
        return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'detail': f'Payment error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    pt = PaymentTransaction.objects.create(
        user=request.user,
        donation_request=donation_request,
        amount=amount,
        currency=currency,
        gateway='stripe',
        transaction_id=result['payment_intent_id'],
        status='pending',
    )

    return Response({
        'client_secret': result['client_secret'],
        'payment_intent_id': result['payment_intent_id'],
        'payment_transaction_id': pt.id,
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def stripe_confirm_payment(request):
    """
    POST /api/payments/confirm/
    Body: { payment_intent_id, donation_request_id, amount, donation_type? }
    Verifies payment with Stripe, creates DonationTransaction, updates campaign.
    """
    serializer = ConfirmPaymentSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    payment_intent_id = data['payment_intent_id']
    donation_request_id = data['donation_request_id']
    amount = Decimal(str(data['amount']))
    donation_type = data.get('donation_type', 'one_time')

    try:
        intent = verify_payment_intent(payment_intent_id)
    except Exception as e:
        return Response({'detail': f'Payment verification failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

    if intent.status != 'succeeded':
        pt = PaymentTransaction.objects.filter(
            transaction_id=payment_intent_id,
            user=request.user,
        ).first()
        if pt:
            pt.status = 'failed'
            pt.save(update_fields=['status'])
        return Response(
            {'detail': f'Payment not completed. Status: {intent.status}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    pt = PaymentTransaction.objects.filter(
        transaction_id=payment_intent_id,
        user=request.user,
    ).first()
    if not pt:
        return Response({'detail': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)
    if pt.status == 'succeeded':
        if pt.donation_transaction_id:
            return Response(
                DonationTransactionSerializer(pt.donation_transaction).data,
                status=status.HTTP_200_OK,
            )
        return Response({'detail': 'Payment already confirmed.'}, status=status.HTTP_200_OK)

    try:
        donation_request = DonationRequest.objects.get(pk=donation_request_id)
    except DonationRequest.DoesNotExist:
        pt.status = 'failed'
        pt.save(update_fields=['status'])
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    dt = DonationTransaction.objects.create(
        user=request.user,
        donation_request=donation_request,
        amount=amount,
        currency=pt.currency,
        donation_type=donation_type,
        status='completed',
        payment_reference=payment_intent_id,
        gateway_reference=payment_intent_id,
    )

    pt.donation_transaction = dt
    pt.status = 'succeeded'
    pt.save(update_fields=['donation_transaction', 'status'])

    donation_request, goal_reached = _apply_payment_to_request(donation_request, amount)
    notify_donation_made(donation_request, request.user, amount)
    _broadcast_donation(donation_request)

    if goal_reached:
        notify_campaign_goal_reached(donation_request)

    return Response(DonationTransactionSerializer(dt).data, status=status.HTTP_201_CREATED)


def _get_redirect_base_url(request):
    """Base URL for eSewa redirects (success/failure)."""
    import os
    base = os.getenv('ESEWA_REDIRECT_BASE_URL') or os.getenv('API_BASE_URL')
    if base:
        base = base.strip()
        if base and base.lower() not in ('auto', 'default'):
            return base.rstrip('/')
    scheme = 'https' if request.is_secure() else 'http'
    host = request.get_host()
    return f'{scheme}://{host}'


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def esewa_init(request):
    """
    POST /api/payments/esewa-init/
    Body: { donation_request_id, amount (NPR), donation_type? }
    Creates eSewa payment, returns direct form_url and form_data for client to submit.
    """
    if not is_esewa_configured():
        return Response(
            {'detail': 'eSewa is not configured. Set ESEWA_SECRET_KEY in .env'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    serializer = EsewaInitSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    donation_request_id = data['donation_request_id']
    amount = Decimal(str(data['amount']))
    donation_type = data.get('donation_type', 'one_time')

    try:
        donation_request = DonationRequest.objects.get(pk=donation_request_id)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    base_url = _get_redirect_base_url(request)
    success_url = f'{base_url}/api/payments/esewa-callback/'
    failure_url = f'{base_url}/api/payments/esewa-failure/'

    form_data = create_esewa_payment(
        amount=amount,
        success_url=success_url,
        failure_url=failure_url,
    )
    transaction_uuid = form_data['transaction_uuid']

    pt = PaymentTransaction.objects.create(
        user=request.user,
        donation_request=donation_request,
        amount=amount,
        currency='NPR',
        gateway='esewa',
        transaction_id=transaction_uuid,
        donation_type=donation_type,
        status='pending',
    )

    return Response({
        'form_url': form_data['form_url'],
        'form_data': {
            'amount': form_data['amount'],
            'tax_amount': form_data['tax_amount'],
            'total_amount': form_data['total_amount'],
            'transaction_uuid': form_data['transaction_uuid'],
            'product_code': form_data['product_code'],
            'product_service_charge': form_data['product_service_charge'],
            'product_delivery_charge': form_data['product_delivery_charge'],
            'success_url': form_data['success_url'],
            'failure_url': form_data['failure_url'],
            'signed_field_names': form_data['signed_field_names'],
            'signature': form_data['signature'],
        },
        'transaction_uuid': transaction_uuid,
        'payment_transaction_id': pt.id,
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([AllowAny])
def esewa_form(request):
    """
    GET /api/payments/esewa-form/?transaction_uuid=xxx
    Backward compatibility: Renders HTML form that auto-submits to eSewa.
    Note: Preferred approach is to directly submit from esewa-init response.
    """
    transaction_uuid = request.GET.get('transaction_uuid')
    if not transaction_uuid:
        return HttpResponse('Missing transaction_uuid', status=400)

    pt = PaymentTransaction.objects.filter(
        transaction_id=transaction_uuid,
        gateway='esewa',
        status='pending',
    ).first()
    if not pt:
        return HttpResponse('Invalid or expired transaction', status=404)

    base_url = _get_redirect_base_url(request)
    form_data = create_esewa_payment(
        amount=pt.amount,
        success_url=f"{base_url}/api/payments/esewa-callback/",
        failure_url=f"{base_url}/api/payments/esewa-failure/",
        transaction_uuid=transaction_uuid,
    )

    form_url = form_data['form_url']
    # Quote all values for HTML attributes (signature/base64 may contain & + " etc.)
    def q(v):
        return html.escape(str(v), quote=True)

    page = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Continue to eSewa</title>
<style>
  body {{ font-family: system-ui, sans-serif; text-align: center; padding: 24px; background: #f5f5f5; }}
  .card {{ background: #fff; border-radius: 12px; padding: 24px; max-width: 420px; margin: 0 auto;
    box-shadow: 0 2px 12px rgba(0,0,0,0.08); }}
  .btn {{ margin-top: 20px; padding: 14px 28px; font-size: 17px; font-weight: 600;
    background: #60bb46; color: #fff; border: none; border-radius: 10px; cursor: pointer; width: 100%; }}
  .hint {{ color: #666; font-size: 14px; margin-top: 16px; line-height: 1.4; }}
</style>
</head>
<body onload="document.getElementById('esewaForm').submit();">
<div class="card">
  <p style="margin:0 0 8px;font-size:16px;">Opening eSewa payment…</p>
  <p class="hint">If nothing happens, tap the button below (some in-app browsers block auto-submit).</p>
  <form id="esewaForm" action="{q(form_url)}" method="POST">
    <input type="hidden" name="amount" value="{q(form_data['amount'])}">
    <input type="hidden" name="tax_amount" value="{q(form_data['tax_amount'])}">
    <input type="hidden" name="total_amount" value="{q(form_data['total_amount'])}">
    <input type="hidden" name="transaction_uuid" value="{q(form_data['transaction_uuid'])}">
    <input type="hidden" name="product_code" value="{q(form_data['product_code'])}">
    <input type="hidden" name="product_service_charge" value="{q(form_data['product_service_charge'])}">
    <input type="hidden" name="product_delivery_charge" value="{q(form_data['product_delivery_charge'])}">
    <input type="hidden" name="success_url" value="{q(form_data['success_url'])}">
    <input type="hidden" name="failure_url" value="{q(form_data['failure_url'])}">
    <input type="hidden" name="signed_field_names" value="{q(form_data['signed_field_names'])}">
    <input type="hidden" name="signature" value="{q(form_data['signature'])}">
    <button type="submit" class="btn">Pay with eSewa</button>
  </form>
</div>
</body>
</html>'''
    return HttpResponse(page, content_type='text/html; charset=utf-8')


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def esewa_callback(request):
    """
    GET /api/payments/esewa-callback/?data=base64
    eSewa redirects here after successful payment. Verify and create DonationTransaction.
    """
    def _param(key: str):
        # eSewa may send callback payload via GET query string or POST form fields.
        v = None
        try:
            if request.method == 'POST' and hasattr(request, 'data'):
                v = request.data.get(key)
        except Exception:
            v = None
        if v is None:
            v = request.GET.get(key)
        return v

    data = None
    data_b64 = _param('data')
    if data_b64:
        try:
            data = json.loads(base64.b64decode(data_b64).decode('utf-8'))
        except Exception:
            return HttpResponse(
                '<html><body><h2>Payment callback error: invalid data</h2></body></html>',
                status=400,
            )
    else:
        # Legacy or alternative eSewa redirect formats.
        data = {
            'status': _param('status') or _param('su'),
            'transaction_uuid': _param('transaction_uuid')
            or _param('oid')
            or _param('pid'),
            'total_amount': _param('total_amount')
            or _param('amt')
            or _param('tAmt')
            or _param('tamt'),
            'transaction_code': _param('transaction_code')
            or _param('refId')
            or _param('rid'),
        }
        signed_field_names = _param('signed_field_names')
        signature = _param('signature')
        if signed_field_names and signature:
            data['signed_field_names'] = signed_field_names
            data['signature'] = signature

    if not data:
        return HttpResponse(
            '<html><body><h2>Payment callback error: missing data</h2></body></html>',
            status=400,
        )

    if 'signed_field_names' in data and 'signature' in data:
        if not verify_esewa_response(data):
            return HttpResponse(
                '<html><body><h2>Payment verification failed</h2></body></html>',
                status=400,
            )

    status_val = data.get('status', '')
    transaction_uuid = data.get('transaction_uuid', '')
    total_amount = data.get('total_amount', 0)
    transaction_code = data.get('transaction_code', '')

    if status_val != 'COMPLETE':
        return HttpResponse(
            f'<html><body><h2>Payment not completed. Status: {status_val}</h2></body></html>',
            status=400,
        )

    pt = PaymentTransaction.objects.filter(
        transaction_id=transaction_uuid,
        gateway='esewa',
        status='pending',
    ).select_related('donation_request').first()
    if not pt:
        return HttpResponse(
            '<html><body><h2>Transaction not found</h2></body></html>',
            status=404,
        )

    amount = Decimal(str(total_amount))
    donation_request = pt.donation_request
    dt = DonationTransaction.objects.create(
        user=pt.user,
        donation_request=donation_request,
        amount=amount,
        currency='NPR',
        donation_type=pt.donation_type,  # Use stored donation_type
        status='completed',
        payment_reference=transaction_code,
        gateway_reference=transaction_code,
    )
    pt.donation_transaction = dt
    pt.status = 'succeeded'
    pt.save(update_fields=['donation_transaction', 'status'])

    if donation_request:
        donation_request, goal_reached = _apply_payment_to_request(donation_request, amount)
        notify_donation_made(donation_request, pt.user, amount)
        _broadcast_donation(donation_request)
        if goal_reached:
            notify_campaign_goal_reached(donation_request)

    amt_display = html.escape(str(amount), quote=False)
    success_html = f'''<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Successful</title>
<style>
body{{font-family:sans-serif;text-align:center;padding:40px;background:#f5f5f5;}}
.box{{background:white;padding:30px;border-radius:12px;max-width:400px;margin:0 auto;box-shadow:0 2px 10px rgba(0,0,0,0.1);}}
h2{{color:#2e7d32;}}
.btn{{display:inline-block;margin-top:20px;padding:12px 24px;background:#2e7d32;color:white;text-decoration:none;border-radius:8px;}}
</style>
</head>
<body onload="window.location='sharecare://payment/success';">
<div class="box">
<h2>Payment Successful!</h2>
<p>Thank you for your donation of {amt_display} NPR.</p>
<p><a href="sharecare://payment/success" class="btn">Return to ShareCare</a></p>
</div>
</body>
</html>'''
    return HttpResponse(success_html, content_type='text/html; charset=utf-8')


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def esewa_failure(request):
    """eSewa redirects here on payment failure."""
    html = '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Payment Failed</title>
<style>
body{font-family:sans-serif;text-align:center;padding:40px;background:#f5f5f5;}
.box{background:white;padding:30px;border-radius:12px;max-width:400px;margin:0 auto;box-shadow:0 2px 10px rgba(0,0,0,0.1);}
h2{color:#c62828;}
.btn{display:inline-block;margin-top:20px;padding:12px 24px;background:#2e7d32;color:white;text-decoration:none;border-radius:8px;}
</style>
</head>
<body onload="window.location='sharecare://payment/failure';">
<div class="box">
<h2>Payment Failed</h2>
<p>The payment could not be completed.</p>
<p><a href="sharecare://payment/failure" class="btn">Return to ShareCare</a></p>
</div>
</body>
</html>
'''
    return HttpResponse(html, content_type='text/html; charset=utf-8')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def donation_pay(request):
    """
    POST /api/donations/pay/
    DEPRECATED: Mock gateway removed. Use Stripe (POST /api/payments/create-intent/) or eSewa (POST /api/payments/esewa-init/).
    """
    return Response(
        {
            'detail': 'Mock payment is no longer supported. Please use Stripe (card) or eSewa for payments.',
            'stripe_create_intent': '/api/payments/create-intent/',
            'esewa_init': '/api/payments/esewa-init/',
        },
        status=status.HTTP_410_GONE,
    )


def _broadcast_donation(donation_request):
    """Broadcast donation update via WebSocket for real-time progress bar."""
    try:
        channel_layer = get_channel_layer()
        if channel_layer:
            async_to_sync(channel_layer.group_send)(
                f'campaign_{donation_request.id}',
                {
                    'type': 'donation_update',
                    'campaign_id': donation_request.id,
                    'raised_amount': str(donation_request.raised_amount),
                    'goal_amount': str(donation_request.goal_amount),
                    'percent_funded': donation_request.percent_funded,
                },
            )
    except Exception:
        pass


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def payment_confirm(request):
    """DEPRECATED: Mock offer confirmation removed. Use Stripe or eSewa for payments."""
    return Response(
        {'detail': 'Offer-based mock payment is no longer supported. Use Stripe or eSewa.'},
        status=status.HTTP_410_GONE,
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def transaction_receipt(request, pk):
    """GET /api/payments/transactions/<id>/receipt/ - PDF receipt for a specific transaction."""
    from django.http import HttpResponse
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
    from io import BytesIO

    txn = DonationTransaction.objects.filter(user=request.user, pk=pk).select_related('donation_request').first()
    if not txn:
        return Response({'detail': 'Transaction not found.'}, status=status.HTTP_404_NOT_FOUND)
    if txn.status not in ('completed', 'confirmed'):
        return Response({'detail': 'Receipt only available for completed donations.'}, status=status.HTTP_400_BAD_REQUEST)

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=72, leftMargin=72, topMargin=72, bottomMargin=18)
    styles = getSampleStyleSheet()
    story = [
        Paragraph('ShareCare Donation Receipt', styles['Title']),
        Spacer(1, 0.3 * 72),
        Paragraph(f'Receipt #: {txn.id}', styles['Normal']),
        Paragraph(f'Date: {txn.created_at.strftime("%Y-%m-%d %H:%M")}', styles['Normal']),
        Paragraph(f'Donor: {request.user.username}', styles['Normal']),
        Paragraph(f'Campaign: {txn.donation_request.title if txn.donation_request else "N/A"}', styles['Normal']),
        Paragraph(f'Amount: {txn.amount} {txn.currency}', styles['Normal']),
        Paragraph(f'Type: {txn.get_donation_type_display()}', styles['Normal']),
        Paragraph('Thank you for your donation!', styles['Normal']),
    ]
    doc.build(story)
    buffer.seek(0)
    response = HttpResponse(buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="sharecare_receipt_{txn.id}.pdf"'
    return response

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def esewa_mobile_init(request):
    if not is_esewa_configured():
        return Response(
            {'detail': 'eSewa is not configured. Set ESEWA_SECRET_KEY in .env'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    serializer = EsewaInitSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    donation_request_id = data['donation_request_id']
    amount = Decimal(str(data['amount']))
    donation_type = data.get('donation_type', 'one_time')

    try:
        donation_request = DonationRequest.objects.get(pk=donation_request_id)
    except DonationRequest.DoesNotExist:
        return Response({'detail': 'Campaign not found.'}, status=status.HTTP_404_NOT_FOUND)

    import uuid
    transaction_uuid = str(uuid.uuid4()).replace('-', '')[:20]

    pt = PaymentTransaction.objects.create(
        user=request.user,
        donation_request=donation_request,
        amount=amount,
        currency='NPR',
        gateway='esewa',
        transaction_id=transaction_uuid,
        donation_type=donation_type,
        status='pending',
    )

    return Response({
        'product_id': transaction_uuid,
        'product_name': donation_request.title[:50],
        'amount': str(amount),
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def esewa_mobile_confirm(request):
    serializer = EsewaMobileConfirmSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    product_id = data['product_id']
    ref_id = data['ref_id']
    amount = Decimal(str(data['total_amount']))

    pt = PaymentTransaction.objects.filter(
        transaction_id=product_id,
        user=request.user,
        gateway='esewa',
        status='pending'
    ).select_related('donation_request').first()

    if not pt:
        return Response({'detail': 'Transaction not found or already processed.'}, status=status.HTTP_404_NOT_FOUND)

    verify_data = verify_esewa_mobile_transaction(ref_id)
    esewa_status = str(verify_data.get('transactionDetails', {}).get('status', '')).upper()

    if esewa_status not in ('COMPLETE', 'SUCCESS', 'SUCCEEDED'):
        pt.status = 'failed'
        pt.save(update_fields=['status'])
        return Response({'detail': f'Transaction verification failed. Status: {esewa_status}'}, status=status.HTTP_400_BAD_REQUEST)

    donation_request = pt.donation_request
    dt = DonationTransaction.objects.create(
        user=pt.user,
        donation_request=donation_request,
        amount=pt.amount,
        currency='NPR',
        donation_type=pt.donation_type,
        status='completed',
        payment_reference=ref_id,
        gateway_reference=ref_id,
    )
    pt.donation_transaction = dt
    pt.status = 'succeeded'
    pt.save(update_fields=['donation_transaction', 'status'])

    if donation_request:
        donation_request, goal_reached = _apply_payment_to_request(donation_request, pt.amount)
        notify_donation_made(donation_request, pt.user, pt.amount)
        _broadcast_donation(donation_request)

        if goal_reached:
            notify_campaign_goal_reached(donation_request)

    return Response(DonationTransactionSerializer(dt).data, status=status.HTTP_200_OK)
