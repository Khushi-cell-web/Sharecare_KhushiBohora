from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0004_userprofile_verification_id'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='location',
            field=models.CharField(blank=True, default='', help_text='City or area for matchmaking', max_length=255),
        ),
    ]
