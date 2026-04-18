# Generated manually for Life Donations models.

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('users', '0008_userprofile_is_organ_pledged_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='BloodDonation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('full_name', models.CharField(max_length=255)),
                ('age', models.PositiveSmallIntegerField()),
                ('blood_group', models.CharField(choices=[('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'), ('O+', 'O+'), ('O-', 'O-'), ('AB+', 'AB+'), ('AB-', 'AB-')], max_length=8)),
                ('contact_number', models.CharField(max_length=32)),
                ('first_time_donor', models.BooleanField(default=False)),
                ('last_donation_declared', models.DateField(blank=True, help_text='Self-reported last donation (null if first-time donor).', null=True)),
                ('health_no_illness', models.BooleanField(default=False)),
                ('health_not_on_medication', models.BooleanField(default=False)),
                ('health_meets_weight_requirements', models.BooleanField(default=False)),
                ('consent_information_correct', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='blood_donations', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'users_blood_donation',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='OrganPledge',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('full_name', models.CharField(max_length=255)),
                ('date_of_birth', models.DateField()),
                ('gender', models.CharField(choices=[('male', 'Male'), ('female', 'Female'), ('other', 'Other'), ('prefer_not_say', 'Prefer not to say')], max_length=20)),
                ('address', models.TextField()),
                ('contact_number', models.CharField(max_length=32)),
                ('email', models.EmailField(max_length=254)),
                ('organs', models.JSONField(default=list, help_text='List of organ identifiers, e.g. ["Heart","Kidney"].')),
                ('emergency_contact_name', models.CharField(max_length=255)),
                ('emergency_contact_phone', models.CharField(max_length=32)),
                ('medical_notes', models.TextField(blank=True, default='')),
                ('consent_organ_donation', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='organ_pledge', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'users_organ_pledge',
            },
        ),
    ]
