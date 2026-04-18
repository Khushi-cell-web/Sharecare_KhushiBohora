# Generated migration for DonationRequest image and gallery_images

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0005_impactupdate'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationrequest',
            name='image',
            field=models.ImageField(blank=True, max_length=500, null=True, upload_to='campaigns/'),
        ),
        migrations.AddField(
            model_name='donationrequest',
            name='gallery_images',
            field=models.JSONField(blank=True, default=list, help_text='List of gallery image URLs'),
        ),
    ]
