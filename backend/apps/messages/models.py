"""
Messages app: 1-to-1 conversations and messages; WebSocket for real-time delivery.
"""
from django.conf import settings
from django.db import models


class Conversation(models.Model):
    """1-to-1 conversation between two users. user1_id < user2_id for uniqueness."""
    user1 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='conversations_as_user1',
    )
    user2 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='conversations_as_user2',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'messages_conversation'
        ordering = ['-updated_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user1', 'user2'],
                name='messages_conversation_unique_pair',
            ),
            models.CheckConstraint(
                condition=models.Q(user1_id__lt=models.F('user2_id')),
                name='messages_conversation_user1_lt_user2',
            ),
        ]

    def __str__(self):
        return f"Conversation {self.id} ({self.user1.username} & {self.user2.username})"

    def other_user(self, user):
        """Return the other participant."""
        return self.user2 if user == self.user1 else self.user1

    @classmethod
    def get_or_create_between(cls, user_a, user_b):
        u1, u2 = (user_a, user_b) if user_a.id < user_b.id else (user_b, user_a)
        conv, _ = cls.objects.get_or_create(user1=u1, user2=u2)
        return conv


class Message(models.Model):
    """Single message in a conversation."""
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages',
    )
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    donation_request = models.ForeignKey(
        'donations.DonationRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chat_messages',
    )
    donation = models.ForeignKey(
        'donations.Donation',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chat_messages',
    )

    class Meta:
        db_table = 'messages_message'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender.username}: {self.text[:50]}..."
