# Importing common provides default settings, see:
# https://github.com/taigaio/taiga-back/blob/master/settings/common.py
from .common import *

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('TAIGA_DB_NAME'),
        'HOST': os.getenv('TAIGA_DB_HOST'),
        'USER': os.getenv('TAIGA_DB_USER'),
        'PASSWORD': os.getenv('TAIGA_DB_PASSWORD')
    }
}

TAIGA_HOSTNAME = os.getenv('TAIGA_HOSTNAME')

SITES['api']['domain'] = TAIGA_HOSTNAME
SITES['front']['domain'] = TAIGA_HOSTNAME

MEDIA_URL  = 'http://' + TAIGA_HOSTNAME + '/media/'
STATIC_URL = 'http://' + TAIGA_HOSTNAME + '/static/'

if os.getenv('TAIGA_SSL') and os.getenv('TAIGA_SSL').lower() == 'true' or \
        os.getenv('TAIGA_SSL_BY_REVERSE_PROXY') and os.getenv('TAIGA_SSL_BY_REVERSE_PROXY').lower() == 'true':
    SITES['api']['scheme'] = 'https'
    SITES['front']['scheme'] = 'https'

    MEDIA_URL  = 'https://' + TAIGA_HOSTNAME + '/media/'
    STATIC_URL = 'https://' + TAIGA_HOSTNAME + '/static/'

SECRET_KEY = os.getenv('TAIGA_SECRET_KEY')
TAIGA_ENABLE_EVENTS = os.getenv('TAIGA_ENABLE_EVENTS')
if TAIGA_ENABLE_EVENTS and TAIGA_ENABLE_EVENTS.lower() == 'true':
    from .celery import *

    CELERY_RESULT_BACKEND = 'redis://redis:6379/0'
    CELERY_ENABLED = True

    BROKER_URL = 'amqp://taiga:taiga@rabbitmq:5672/taiga'
    EVENTS_PUSH_BACKEND = "taiga.events.backends.rabbitmq.EventsPushBackend"
    EVENTS_PUSH_BACKEND_OPTIONS = {"url": "amqp://taiga:taiga@rabbitmq:5672/taiga"}

if os.getenv('TAIGA_ENABLE_EMAIL').lower() == 'true':
    DEFAULT_FROM_EMAIL = os.getenv('TAIGA_EMAIL_FROM')
    CHANGE_NOTIFICATIONS_MIN_INTERVAL = 300 # in seconds

    EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'

    if os.getenv('TAIGA_EMAIL_USE_TLS').lower() == 'true':
        EMAIL_USE_TLS = True
    else:
        EMAIL_USE_TLS = False

    EMAIL_HOST = os.getenv('TAIGA_EMAIL_HOST')
    EMAIL_PORT = int(os.getenv('TAIGA_EMAIL_PORT'))
    EMAIL_HOST_USER = os.getenv('TAIGA_EMAIL_USER')
    EMAIL_HOST_PASSWORD = os.getenv('TAIGA_EMAIL_PASS')
