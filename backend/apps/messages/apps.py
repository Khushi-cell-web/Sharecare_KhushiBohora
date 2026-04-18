from django.apps import AppConfig


class MessagesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.messages'
    label = 'chat'  # avoid conflict with django.contrib.messages
    verbose_name = 'Messages'
