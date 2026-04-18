# Generated migration for Notification model

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('notification_type', models.CharField(choices=[('donation_available', 'New donation available nearby'), ('offer_accepted', 'Volunteer accepted your donation'), ('donation_picked', 'Donation picked up'), ('donation_delivered', 'Donation delivered'), ('payment_successful', 'Payment successful'), ('offer_received', 'You received a new donation offer'), ('task_assigned', 'New task assigned to you'), ('task_completed', 'Task completed successfully')], max_length=50)),
                ('title', models.CharField(max_length=255)),
                ('message', models.TextField()),
                ('is_read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('donation_offer', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='api.donationoffer')),
                ('donation_request', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='api.donationrequest')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to=settings.AUTH_USER_MODEL)),
                ('volunteer_task', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='api.volunteertask')),
            ],
            options={
                'db_table': 'api_notification',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['user', '-created_at'], name='api_notifi_user_id_created__idx'),
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['user', 'is_read'], name='api_notifi_user_id_is_read_idx'),
        ),
    ]
