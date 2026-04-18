
from django.urls import path
from . import views_life_donations

app_name = "life_donations"

urlpatterns = [
    path("blood/status/", views_life_donations.blood_status, name="blood-status"),
    path("blood/register/", views_life_donations.register_blood, name="blood-register"),
    path("organ/status/", views_life_donations.organ_status, name="organ-status"),
    path("organ/pledge/", views_life_donations.register_organ_pledge, name="organ-pledge"),
]

