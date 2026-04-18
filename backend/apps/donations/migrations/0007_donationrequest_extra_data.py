# Generated migration for DonationRequest extra_data (category-specific structured data)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0006_donationrequest_media'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationrequest',
            name='extra_data',
            field=models.JSONField(blank=True, default=dict, help_text='Category-specific structured data'),
        ),
    ]
