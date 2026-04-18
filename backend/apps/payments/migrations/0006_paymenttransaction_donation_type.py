# Generated migration for adding donation_type field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0005_alter_paymenttransaction_gateway'),
    ]

    operations = [
        migrations.AddField(
            model_name='paymenttransaction',
            name='donation_type',
            field=models.CharField(
                choices=[('one_time', 'One-time'), ('recurring', 'Recurring')],
                default='one_time',
                max_length=20
            ),
        ),
    ]
