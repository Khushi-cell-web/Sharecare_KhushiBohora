"""
eSewa ePay v2 integration for Nepal.
UAT: https://rc-epay.esewa.com.np/api/epay/main/v2/form
Prod: https://epay.esewa.com.np/api/epay/main/v2/form
"""
import base64
import hashlib
import hmac
import os
import uuid
from decimal import Decimal
from typing import Optional

from django.conf import settings


def _get_esewa_secret() -> Optional[str]:
    return os.getenv('ESEWA_SECRET_KEY') or getattr(settings, 'ESEWA_SECRET_KEY', None)


def _get_esewa_product_code() -> str:
    return os.getenv('ESEWA_PRODUCT_CODE', 'EPAYTEST')


def _get_esewa_form_url() -> str:
    env = os.getenv('ESEWA_ENVIRONMENT', 'uat').lower()
    if env == 'production' or env == 'prod':
        return 'https://epay.esewa.com.np/api/epay/main/v2/form'
    return 'https://rc-epay.esewa.com.np/api/epay/main/v2/form'


def _generate_signature(total_amount: str, transaction_uuid: str, product_code: str) -> str:
    """HMAC-SHA256 signature for eSewa. Message: total_amount=X,transaction_uuid=Y,product_code=Z"""
    secret = _get_esewa_secret()
    if not secret:
        raise ValueError('eSewa is not configured. Set ESEWA_SECRET_KEY in .env')
    message = f'total_amount={total_amount},transaction_uuid={transaction_uuid},product_code={product_code}'
    sig = hmac.new(
        secret.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256,
    ).digest()
    return base64.b64encode(sig).decode('utf-8')


def verify_esewa_response(data: dict) -> bool:
    """Verify eSewa callback signature. signed_field_names order matters."""
    signed_names = data.get('signed_field_names', '')
    if not signed_names:
        return False
    parts = []
    for name in signed_names.split(','):
        name = name.strip()
        val = data.get(name)
        if val is not None:
            parts.append(f'{name}={val}')
    message = ','.join(parts)
    received_sig = data.get('signature', '')
    secret = _get_esewa_secret()
    if not secret:
        return False
    expected = base64.b64encode(
        hmac.new(secret.encode('utf-8'), message.encode('utf-8'), hashlib.sha256).digest()
    ).decode('utf-8')
    return hmac.compare_digest(expected, received_sig)


def create_esewa_payment(
    amount: Decimal,
    success_url: str,
    failure_url: str,
    transaction_uuid: Optional[str] = None,
) -> dict:
    """
    Create eSewa payment form data.
    Amount in NPR (no decimal for eSewa - use int). Tax/charges = 0 for donations.
    Returns dict with all form fields for POST to eSewa.
    """
    secret = _get_esewa_secret()
    if not secret:
        raise ValueError('eSewa is not configured. Set ESEWA_SECRET_KEY in .env')

    product_code = _get_esewa_product_code()
    amt = str(int(amount))
    tax = '0'
    service_charge = '0'
    delivery_charge = '0'
    total = str(int(amount) + int(tax) + int(service_charge) + int(delivery_charge))
    txn_uuid = transaction_uuid or str(uuid.uuid4()).replace('-', '')[:20]

    signature = _generate_signature(total, txn_uuid, product_code)

    return {
        'form_url': _get_esewa_form_url(),
        'amount': amt,
        'tax_amount': tax,
        'total_amount': total,
        'transaction_uuid': txn_uuid,
        'product_code': product_code,
        'product_service_charge': service_charge,
        'product_delivery_charge': delivery_charge,
        'success_url': success_url,
        'failure_url': failure_url,
        'signed_field_names': 'total_amount,transaction_uuid,product_code',
        'signature': signature,
    }


def verify_esewa_mobile_transaction(ref_id: str) -> dict:
    """Verify eSewa mobile SDK transaction."""
    import requests
    import json as json_module
    
    env = os.getenv('ESEWA_ENVIRONMENT', 'uat').lower()
    
    # Credentials from eSewa docs for Mobile SDK
    merchant_id = os.getenv('ESEWA_MERCHANT_ID', "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R")
    merchant_secret = os.getenv('ESEWA_MERCHANT_SECRET', "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==")

    if env in ('production', 'prod'):
        url = "https://esewa.com.np/mobile/transaction"
    else:
        url = "https://rc.esewa.com.np/mobile/transaction"
        
    headers = {
        'merchantId': merchant_id,
        'merchantSecret': merchant_secret,
        'Content-Type': 'application/json',
    }
    params = {'txnRefId': ref_id}
    
    try:
        print(f"\n[eSewa Verify] URL: {url}")
        print(f"[eSewa Verify] RefId: {ref_id}")
        print(f"[eSewa Verify] Merchant ID: {merchant_id[:20]}...")
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        print(f"[eSewa Verify] Status Code: {response.status_code}")
        print(f"[eSewa Verify] Response: {response.text[:500]}")
        
        response.raise_for_status()
        data = response.json()

        # eSewa mobile verify can return either a list payload or object payload.
        if isinstance(data, list):
            if not data:
                return {}
            candidate = data[0] if isinstance(data[0], dict) else {}
            if not isinstance(candidate, dict):
                return {}
            if isinstance(candidate.get('transactionDetails'), dict):
                return candidate
            status_val = candidate.get('status') or candidate.get('transactionStatus')
            return {
                **candidate,
                'transactionDetails': {
                    'status': str(status_val or ''),
                },
            }

        if isinstance(data, dict):
            if isinstance(data.get('transactionDetails'), dict):
                return data
            status_val = data.get('status') or data.get('transactionStatus')
            if status_val is None and isinstance(data.get('data'), dict):
                nested = data['data']
                status_val = nested.get('status') or nested.get('transactionStatus')
            return {
                **data,
                'transactionDetails': {
                    'status': str(status_val or ''),
                },
            }

        return {}
    except requests.exceptions.HTTPError as e:
        print(f"[eSewa Verify] HTTP Error: {e.response.status_code}")
        print(f"[eSewa Verify] Response: {e.response.text}")
        try:
            error_data = e.response.json()
            print(f"[eSewa Verify] Error data: {json_module.dumps(error_data, indent=2)}")
        except:
            pass
        return {}
    except Exception as e:
        print(f"[eSewa Verify] Error: {e}")
        import traceback
        traceback.print_exc()
        return {}


def is_esewa_configured() -> bool:
    return bool(_get_esewa_secret())
