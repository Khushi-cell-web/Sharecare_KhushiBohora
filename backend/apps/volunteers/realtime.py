"""Real-time delivery task updates via Django Channels."""
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


def user_can_subscribe_delivery_task(user, task) -> bool:
    """Donor, NGO creator, assigned volunteer, or any volunteer while task is claimable."""
    if not user or not getattr(user, 'is_authenticated', False):
        return False
    uid = user.pk
    if task.volunteer_id and task.volunteer_id == uid:
        return True
    if (
        task.task_status == 'pending_volunteer'
        and not task.volunteer_id
        and getattr(user, 'role', None) == 'volunteer'
    ):
        return True
    if task.donation_offer_id and task.donation_offer.donor_id == uid:
        return True
    if task.donation_id and task.donation.donor_id == uid:
        return True
    if task.donation_request_id and task.donation_request.created_by_id == uid:
        return True
    if task.donation_id and task.donation.donation_request_id:
        dr = task.donation.donation_request
        if dr and dr.created_by_id == uid:
            return True
    return False


def build_delivery_payload(task) -> dict:
    from .models import VolunteerTask

    if not isinstance(task, VolunteerTask):
        return {}
    vol_username = ''
    vol_id = None
    if task.volunteer_id:
        vol_id = task.volunteer_id
        if task.volunteer:
            vol_username = task.volunteer.get_username()
    return {
        'type': 'delivery_task_update',
        'task_id': task.pk,
        'task_status': task.task_status,
        'task_status_display': task.get_task_status_display(),
        'pickup_location': task.pickup_location,
        'delivery_location': task.delivery_location,
        'pickup_latitude': task.pickup_latitude,
        'pickup_longitude': task.pickup_longitude,
        'delivery_latitude': task.delivery_latitude,
        'delivery_longitude': task.delivery_longitude,
        'volunteer_id': vol_id,
        'volunteer_username': vol_username,
        'donation_request_id': task.donation_request_id,
        'donation_offer_id': task.donation_offer_id,
        'donation_id': task.donation_id,
        'updated_at': task.updated_at.isoformat() if task.updated_at else None,
    }


def broadcast_volunteer_task_update(task_id: int) -> None:
    from .models import VolunteerTask

    try:
        task = VolunteerTask.objects.select_related(
            'volunteer',
            'donation_request',
            'donation_request__created_by',
            'donation_offer',
            'donation_offer__donor',
            'donation',
            'donation__donor',
            'donation__donation_request',
            'donation__donation_request__created_by',
        ).get(pk=task_id)
    except VolunteerTask.DoesNotExist:
        return
    payload = build_delivery_payload(task)
    layer = get_channel_layer()
    if layer is None:
        return
    async_to_sync(layer.group_send)(
        f'delivery_task_{task_id}',
        {'type': 'delivery_task_update', 'payload': payload},
    )
