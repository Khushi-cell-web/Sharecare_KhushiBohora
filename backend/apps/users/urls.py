from django.urls import path

from rest_framework_simplejwt.views import TokenRefreshView

from . import views

app_name = 'users'

urlpatterns = [
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('google/', views.GoogleLoginView.as_view(), name='google-login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('forgot-password/', views.ForgotPasswordView.as_view(), name='forgot-password'),
    path('verify-otp/', views.VerifyOTPView.as_view(), name='verify-otp'),
    path('reset-password/', views.ResetPasswordView.as_view(), name='reset-password'),
    path('me/', views.MeView.as_view(), name='me'),
    path('me/submit-verification/', views.SubmitVerificationView.as_view(), name='submit-verification'),
    path('me/activity/', views.activity_history, name='activity-history'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
]
