# Generated manually for ShareCare volunteer pickup flow

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0008_add_latitude_longitude_to_donation_request'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationoffer',
            name='fulfillment_type',
            field=models.CharField(
                choices=[('self_dropoff', 'I will drop off myself'), ('volunteer_pickup', 'Request a volunteer pickup')],
                default='volunteer_pickup',
                help_text='For material donations: self drop-off vs volunteer pickup.',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='donationoffer',
            name='pickup_location',
            field=models.CharField(blank=True, help_text='Pickup address when fulfillment_type is volunteer_pickup.', max_length=512),
        ),
        migrations.AddField(
            model_name='donationoffer',
            name='pickup_latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='donationoffer',
            name='pickup_longitude',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
