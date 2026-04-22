from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import VolunteerTask


@receiver(post_save, sender=VolunteerTask)
def volunteer_task_broadcast_realtime(sender, instance, **kwargs):
    try:
        from .realtime import broadcast_volunteer_task_update

        broadcast_volunteer_task_update(instance.pk)
    except Exception:
        # Realtime delivery is best-effort and must not break DB write APIs.
        pass
