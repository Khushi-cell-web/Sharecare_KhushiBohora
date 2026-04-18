"""
Payment service layer: Stripe integration.
"""
import os
from decimal import Decimal
from typing import Optional

from django.conf import settings


def _get_stripe_secret() -> Optional[str]:
    return os.getenv('STRIPE_SECRET_KEY') or getattr(settings, 'STRIPE_SECRET_KEY', None)


def create_payment_intent(
    amount: Decimal,
    currency: str = 'USD',
    metadata: Optional[dict] = None,
) -> dict:
    """
    Create a Stripe PaymentIntent. Amount in dollars; Stripe expects cents.
    Returns: { client_secret, payment_intent_id } or raises.
    """
    secret = _get_stripe_secret()
    if not secret:
        raise ValueError('Stripe is not configured. Set STRIPE_SECRET_KEY in .env')

    import stripe
    stripe.api_key = secret

    amount_cents = int(amount * 100)
    if amount_cents < 50:  # Stripe minimum
        raise ValueError('Amount must be at least $0.50')

    intent = stripe.PaymentIntent.create(
        amount=amount_cents,
        currency=currency.lower(),
        automatic_payment_methods={'enabled': True},
        metadata=metadata or {},
    )
    return {
        'client_secret': intent.client_secret,
        'payment_intent_id': intent.id,
    }


def verify_payment_intent(payment_intent_id: str) -> dict:
    """
    Verify PaymentIntent status with Stripe. Returns intent object.
    """
    secret = _get_stripe_secret()
    if not secret:
        raise ValueError('Stripe is not configured')

    import stripe
    stripe.api_key = secret
    return stripe.PaymentIntent.retrieve(payment_intent_id)
