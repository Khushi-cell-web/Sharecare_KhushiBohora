from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import VolunteerTask


@receiver(post_save, sender=VolunteerTask)
def volunteer_task_broadcast_realtime(sender, instance, **kwargs):
    from .realtime import broadcast_volunteer_task_update

    broadcast_volunteer_task_update(instance.pk)
