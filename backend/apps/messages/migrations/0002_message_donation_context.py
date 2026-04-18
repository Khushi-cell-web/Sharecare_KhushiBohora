# Generated manually for optional donation/request context on chat messages.

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0001_initial'),
        ('donations', '0013_alter_donation_category_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='message',
            name='donation',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='chat_messages',
                to='donations.donation',
            ),
        ),
        migrations.AddField(
            model_name='message',
            name='donation_request',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='chat_messages',
                to='donations.donationrequest',
            ),
        ),
    ]
