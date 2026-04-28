from rest_framework import serializers
from .models import CampusZone, ScanEvent, Mission, PlayerMission, RealWorldEvent
from accounts.models import Player

class PlayerSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = Player
        fields = ['username', 'faculty', 'xp', 'level', 'coins', 'current_title', 'daily_streak']

class CampusZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = CampusZone
        fields = '__all__'

class ScanEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScanEvent
        fields = '__all__'

class MissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mission
        fields = '__all__'

class RealWorldEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = RealWorldEvent
        fields = '__all__'
