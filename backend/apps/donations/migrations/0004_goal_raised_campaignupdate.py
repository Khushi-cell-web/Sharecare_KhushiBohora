# Generated migration for goal_amount, raised_amount, CampaignUpdate

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('donations', '0003_add_urgency_to_donationrequest'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationrequest',
            name='goal_amount',
            field=models.DecimalField(
                decimal_places=2,
                default=0,
                help_text='Fundraising goal (0 = N/A)',
                max_digits=12,
            ),
        ),
        migrations.AddField(
            model_name='donationrequest',
            name='raised_amount',
            field=models.DecimalField(
                decimal_places=2,
                default=0,
                help_text='Auto-calculated from transactions',
                max_digits=12,
            ),
        ),
        migrations.CreateModel(
            name='CampaignUpdate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('content', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('created_by', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='campaign_updates_created',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('donation_request', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='campaign_updates',
                    to='donations.donationrequest',
                )),
            ],
            options={
                'db_table': 'donations_campaignupdate',
                'ordering': ['-created_at'],
            },
        ),
    ]
