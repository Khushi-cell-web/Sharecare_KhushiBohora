# Generated migration for PaymentTransaction (Stripe gateway)

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0004_goal_raised_campaignupdate'),
        ('payments', '0003_donationtransaction_updates'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='PaymentTransaction',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('amount', models.DecimalField(decimal_places=2, max_digits=12)),
                ('currency', models.CharField(default='USD', max_length=3)),
                ('gateway', models.CharField(choices=[('stripe', 'Stripe'), ('mock', 'Mock')], default='stripe', max_length=20)),
                ('transaction_id', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('succeeded', 'Succeeded'), ('failed', 'Failed'), ('cancelled', 'Cancelled')], default='pending', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('donation_request', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='payment_transactions', to='donations.donationrequest')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='payment_transactions', to=settings.AUTH_USER_MODEL)),
                ('donation_transaction', models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='payment_record', to='payments.donationtransaction')),
            ],
            options={
                'db_table': 'payments_paymenttransaction',
                'ordering': ['-created_at'],
            },
        ),
    ]
