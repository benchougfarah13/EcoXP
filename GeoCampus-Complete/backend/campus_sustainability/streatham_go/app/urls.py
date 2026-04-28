from django.urls import path
from django.conf.urls.static import static
from django.conf import settings

from . import views
from . import api_views

# set the app name
app_name = 'app'
# create a list of url patterns
urlpatterns = [
    # home page
    path('home/', views.home, name='home'),
    # leaderboard page
    path('leaderboard/', views.leaderboard, name='leaderboard'),
    # ladning page
    path('', views.index, name='index'),
    # GEOCAMPUS API Routes
    path('api/v1/profile/<str:username>/', api_views.get_user_profile, name='api_profile'),
    path('api/v1/map/zones/', api_views.get_campus_zones, name='api_zones'),
    path('api/v1/game/scan/', api_views.scan_plant, name='api_scan'),
    path('api/v1/events/validate/', api_views.validate_event, name='api_validate_event'),
    path('api/v1/leaderboard/', api_views.get_leaderboard, name='api_leaderboard'),
    # play page
    path('play/<token>', views.play, name='play'),
    # conversation javascript (this needs to be rendered)
    path('app/conversion.js', views.conversation, name='conversation'),
    # play javascript (this needs to be rendered)
    path('app/play.js', views.play_js, name='play_js'),
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
# also add the static files to the url patterns
