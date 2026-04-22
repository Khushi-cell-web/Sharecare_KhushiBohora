"""
Django settings for sharecare_backend project.
ShareCare - University mobile app backend.
"""

from pathlib import Path
import os
from datetime import timedelta

from dotenv import load_dotenv

# Project paths
BASE_DIR = Path(__file__).resolve().parent.parent
# Ensure project .env values win over any stale terminal/user env vars.
# This prevents accidental Postgres selection when backend/.env says sqlite.
load_dotenv(BASE_DIR / '.env', override=True)

_google_oauth_client_ids_raw = (
    os.getenv('GOOGLE_OAUTH_CLIENT_IDS', '')
    or os.getenv('GOOGLE_SERVER_CLIENT_ID', '')
)
GOOGLE_OAUTH_CLIENT_IDS = [
    cid.strip() for cid in _google_oauth_client_ids_raw.split(',') if cid.strip()
]

# Security
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-dev-key-change-in-production')
DEBUG = True
ALLOWED_HOSTS = ['*']

# django-jazzmin provides module `jazzmin`; optional so migrate works without it installed.
try:
    import jazzmin  # noqa: F401

    _jazzmin_apps = ['jazzmin']
except ImportError:
    _jazzmin_apps = []

INSTALLED_APPS = [
    *_jazzmin_apps,  # must be before django.contrib.admin when present
    'daphne',  # ASGI server; must be before django.contrib
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'channels',
    # ShareCare modular apps
    'apps.users',
    'apps.donations',
    'apps.volunteers',
    'apps.notifications',
    'apps.adminpanel',
    'apps.payments',
    'apps.messages',
    'apps.support',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'sharecare_backend.csrf_exempt_api.CsrfExemptApiMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'sharecare_backend.urls'
WSGI_APPLICATION = 'sharecare_backend.wsgi.application'
ASGI_APPLICATION = 'sharecare_backend.asgi.application'

# Channels: in-memory layer for dev; use Redis in production (CHANNEL_LAYERS = redis)
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer',
    },
}

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# SQLite is used for local development.
# To use PostgreSQL, set ENV:
#   DB_ENGINE=postgres
#   DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
db_engine = os.getenv('DB_ENGINE', 'sqlite').strip().lower()
if db_engine in ('postgres', 'postgresql'):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv('DB_NAME', 'sharecare'),
            'USER': os.getenv('DB_USER', 'sharecare'),
            'PASSWORD': os.getenv('DB_PASSWORD', ''),
            'HOST': os.getenv('DB_HOST', 'localhost'),
            'PORT': os.getenv('DB_PORT', '5432'),
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

CORS_ALLOW_ALL_ORIGINS = True

# Trusted CSRF origins for web clients on different ports.
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://localhost:56512',
    'http://127.0.0.1:56512',
]

# DRF uses JWT auth only
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': False,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Must be absolute so Django admin links resolve correctly (avoid /admin/static/...).
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

JAZZMIN_SETTINGS = {
    "site_title": "ShareCare Admin",
    "site_header": "ShareCare",
    "site_brand": "ShareCare",
    "site_logo": "img/sharecare_admin_logo.svg",
    "site_logo_classes": "img-fluid",
    "welcome_sign": "ShareCare Control Center",
    "copyright": "ShareCare Ltd",
    "search_model": ["users.User", "donations.DonationRequest"],
    "show_ui_builder": False,
    "custom_css": "css/sharecare_admin_theme.css?v=20260422-1",
    "custom_js": "js/custom_admin.js?v=20260422-1",
    "hide_apps": ["auth", "contenttypes", "sessions"],
}

JAZZMIN_UI_TWEAKS = {
    "navbar": "navbar-dark",
    "theme": "default",
    "dark_mode_theme": "default",
    "sidebar": "sidebar-dark-primary",
    "sidebar_nav_child_indent": True,
    "sidebar_nav_compact_style": False,
    "sidebar_nav_legacy_style": False,
    "sidebar_nav_flat_style": False,
    "theme_color": "primary",
    "accent": "accent-pink",
}

# App user model.
AUTH_USER_MODEL = 'users.User'

# Email (SMTP)
# Default to SMTP so OTP reaches real inboxes even in local debug runs.
# Set EMAIL_DELIVERY_MODE=console in backend/.env only when you explicitly
# want OTP/email output printed to terminal.
email_delivery_mode = os.getenv('EMAIL_DELIVERY_MODE', 'smtp').strip().lower()
if email_delivery_mode == 'console':
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
else:
    EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True

# Gmail SMTP must use an app password.
EMAIL_HOST_USER = 'khushibohora692@gmail.com'
EMAIL_HOST_PASSWORD = 'qhodczygvqjnrobv'
DEFAULT_FROM_EMAIL = 'khushibohora692@gmail.com'
