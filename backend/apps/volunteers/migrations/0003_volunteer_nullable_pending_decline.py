# Generated manually: nullable volunteer, pending_volunteer status, declines

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('volunteers', '0002_alter_volunteertask_donation_offer'),
        ('donations', '0009_donationoffer_fulfillment'),
    ]

    operations = [
        migrations.AlterField(
            model_name='volunteertask',
            name='task_status',
            field=models.CharField(
                choices=[
                    ('pending_volunteer', 'Waiting for volunteer'),
                    ('assigned', 'Accepted by Volunteer'),
                    ('picked', 'Picked Up'),
                    ('in_transit', 'In Transit'),
                    ('delivered', 'Delivered'),
                ],
                default='assigned',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='volunteertask',
            name='volunteer',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='volunteer_tasks',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.CreateModel(
            name='VolunteerTaskDecline',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('volunteer', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='volunteer_task_declines', to=settings.AUTH_USER_MODEL)),
                ('volunteer_task', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='declines', to='volunteers.volunteertask')),
            ],
            options={
                'db_table': 'volunteers_task_decline',
                'unique_together': {('volunteer', 'volunteer_task')},
            },
        ),
    ]
