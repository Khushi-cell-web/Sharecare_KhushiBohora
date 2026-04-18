# DonationRequest.urgency: Low / Medium / High

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('donations', '0002_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='donationrequest',
            name='urgency',
            field=models.CharField(
                choices=[('Low', 'Low'), ('Medium', 'Medium'), ('High', 'High')],
                default='Medium',
                max_length=10,
            ),
        ),
    ]
