# Generated manually for verification_id field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0003_alter_passwordresettoken_expires_at'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='verification_id',
            field=models.CharField(
                blank=True,
                help_text='NGO/Hospital registration or license ID submitted for verification',
                max_length=255,
            ),
        ),
    ]
