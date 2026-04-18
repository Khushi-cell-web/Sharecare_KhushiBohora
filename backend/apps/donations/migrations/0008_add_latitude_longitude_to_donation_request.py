# Generated migration: add latitude/longitude to DonationRequest for map-based pickup location

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0007_donationrequest_extra_data'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationrequest',
            name='latitude',
            field=models.FloatField(blank=True, help_text='Pickup location latitude from map picker', null=True),
        ),
        migrations.AddField(
            model_name='donationrequest',
            name='longitude',
            field=models.FloatField(blank=True, help_text='Pickup location longitude from map picker', null=True),
        ),
    ]
