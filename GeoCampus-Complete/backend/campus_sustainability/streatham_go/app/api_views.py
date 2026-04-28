import os
import sys
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from .models import CampusZone, ScanEvent, Mission, PlayerMission, RealWorldEvent
from accounts.models import Player
from .serializers import PlayerSerializer, CampusZoneSerializer, ScanEventSerializer, MissionSerializer

# To handle plant recognition
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../Hack-main/Hack-main/StudentHunter Main/plant_recognition/plant_recognition_server')))
try:
    from plant_recognition import PlantRecognizer
    recognizer = PlantRecognizer()
except Exception as e:
    recognizer = None
    print(f"Warning: PlantRecognizer failed to load: {e}")

@api_view(['GET'])
@permission_classes([AllowAny]) # For hackathon demo purposes
def get_user_profile(request, username):
    try:
        player = Player.objects.get(user__username=username)
        serializer = PlayerSerializer(player)
        return Response(serializer.data)
    except Player.DoesNotExist:
        return Response({'success': False, 'message': 'Player not found'}, status=404)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_campus_zones(request):
    zones = CampusZone.objects.all()
    serializer = CampusZoneSerializer(zones, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([AllowAny])
def scan_plant(request):
    """
    Expects:
    - image (file)
    - lat (float)
    - lng (float)
    - username (string)
    """
    if not recognizer:
        return Response({"success": False, "message": "Plant AI not configured"}, status=500)
    
    image_file = request.FILES.get('image')
    lat = request.data.get('lat')
    lng = request.data.get('lng')
    username = request.data.get('username')

    if not all([image_file, lat, lng, username]):
        return Response({"success": False, "message": "Missing arguments"}, status=400)

    try:
        player = Player.objects.get(user__username=username)
    except Player.DoesNotExist:
        return Response({"success": False, "message": "User not found"}, status=400)

    # Save temp file for AI
    temp_path = f"/tmp/upload_{image_file.name}"
    with open(temp_path, 'wb+') as f:
        for chunk in image_file.chunks():
            f.write(chunk)
    
    # Run recognition
    result = recognizer.recognize(temp_path)
    os.remove(temp_path)
    
    # Check if match
    if result.get('match') and result.get('confidence', 0) >= 0.40:
        plant_name = result['plant']
        
        # Progression logic
        is_first_scan = not ScanEvent.objects.filter(player=player, plant_name=plant_name).exists()
        gained_xp = 50 if is_first_scan else 10
        player.xp += gained_xp
        
        # Level up logic
        if player.xp > player.level * 100:
            player.level += 1
            player.coins += 20
            
        player.save()
        
        ScanEvent.objects.create(
            player=player,
            plant_name=plant_name,
            confidence=result['confidence'],
            lat=float(lat),
            lng=float(lng),
            is_new_discovery=is_first_scan
        )
        
        return Response({
            "success": True,
            "plant": plant_name,
            "xp_gained": gained_xp,
            "new_discovery": is_first_scan,
            "current_xp": player.xp,
            "level": player.level
        })
    
    return Response({"success": False, "message": "Unrecognized plant or confidence too low"}, status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def validate_event(request):
    """
    Expects:
    - qr_secret (string)
    - username (string)
    """
    qr_secret = request.data.get('qr_secret')
    username = request.data.get('username')
    
    try:
        event = RealWorldEvent.objects.get(qr_code_secret=qr_secret)
        player = Player.objects.get(user__username=username)
        
        # Award xp
        player.xp += event.reward_xp
        player.save()
        
        return Response({
            "success": True, 
            "message": f"Successfully checked into {event.title}!",
            "xp_gained": event.reward_xp
        })
    except RealWorldEvent.DoesNotExist:
        return Response({"success": False, "message": "Invalid Event QR"}, status=404)
    except Player.DoesNotExist:
        return Response({"success": False, "message": "User not found"}, status=404)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_leaderboard(request):
    players = Player.objects.all().order_by('-xp')[:50]
    serializer = PlayerSerializer(players, many=True)
    return Response(serializer.data)
