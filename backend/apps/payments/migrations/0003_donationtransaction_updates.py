# Generated migration for DonationTransaction updates

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0004_goal_raised_campaignupdate'),
        ('payments', '0002_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.RenameField(
            model_name='donationtransaction',
            old_name='donor',
            new_name='user',
        ),
        migrations.AddField(
            model_name='donationtransaction',
            name='donation_request',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='transactions',
                to='donations.donationrequest',
            ),
        ),
        migrations.AddField(
            model_name='donationtransaction',
            name='donation_type',
            field=models.CharField(
                choices=[('one_time', 'One-time'), ('recurring', 'Recurring')],
                default='one_time',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='donationtransaction',
            name='payment_reference',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AlterField(
            model_name='donationtransaction',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('confirmed', 'Confirmed'),
                    ('completed', 'Completed'),
                    ('failed', 'Failed'),
                    ('refunded', 'Refunded'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
    ]
