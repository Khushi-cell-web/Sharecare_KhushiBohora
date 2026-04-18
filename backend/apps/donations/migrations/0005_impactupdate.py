# Generated migration for ImpactUpdate

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0004_goal_raised_campaignupdate'),
    ]

    operations = [
        migrations.CreateModel(
            name='ImpactUpdate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('description', models.TextField()),
                ('images', models.JSONField(blank=True, default=list, help_text='List of image URLs')),
                ('people_helped', models.PositiveIntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('campaign', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='impact_updates',
                    to='donations.donationrequest',
                )),
            ],
            options={
                'db_table': 'donations_impactupdate',
                'ordering': ['-created_at'],
            },
        ),
    ]
