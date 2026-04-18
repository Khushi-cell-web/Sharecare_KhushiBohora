from django.apps import AppConfig


class VolunteersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.volunteers'
    verbose_name = 'Volunteers'

    def ready(self):
        from . import signals  # noqa: F401
