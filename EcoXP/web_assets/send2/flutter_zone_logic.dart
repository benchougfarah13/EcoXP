import 'dart:math' as math;

/// Smart Zone System — logique portable (Flutter / Dart).
/// Même modèle que le backend : zone circulaire (lat, lng, radius en mètres).

class CampusZone {
  const CampusZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.type,
    this.enterMessage,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? type;
  final String? enterMessage;
}

class ZoneContent {
  const ZoneContent({
    required this.id,
    required this.zoneId,
    required this.contentType,
    required this.title,
    this.description,
    this.rewardXp = 0,
    this.rewardCoins = 0,
    this.badgeId,
    this.playPayload,
  });

  final String id;
  final String zoneId;
  final String contentType;
  final String title;
  final String? description;
  final int rewardXp;
  final int rewardCoins;
  final String? badgeId;
  final Map<String, dynamic>? playPayload;
}

double haversineDistanceMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * math.pi / 180;

/// Si plusieurs zones contiennent le point, retourne celle dont le centre est le plus proche.
CampusZone? resolveCurrentZone(Iterable<CampusZone> zones, double lat, double lng) {
  CampusZone? best;
  var bestDist = double.infinity;

  for (final z in zones) {
    final d = haversineDistanceMeters(lat, lng, z.latitude, z.longitude);
    if (d <= z.radiusMeters && d < bestDist) {
      bestDist = d;
      best = z;
    }
  }
  return best;
}

typedef ZoneEnterCallback = void Function(CampusZone zone);
typedef ZoneExitCallback = void Function(CampusZone? previous);

/// Suivi entrée / sortie (à appeler depuis un stream de position GPS).
class ZoneDetectorController {
  ZoneDetectorController({required this.zones});

  final List<CampusZone> zones;
  String? _currentId;

  String? get currentZoneId => _currentId;

  /// Retourne la zone courante après mise à jour, et des flags d’événement.
  ({CampusZone? zone, bool entered, bool exited}) update(double lat, double lng) {
    final resolved = resolveCurrentZone(zones, lat, lng);
    final nextId = resolved?.id;
    final prevId = _currentId;

    var entered = false;
    var exited = false;

    if (nextId != prevId) {
      if (prevId != null && nextId == null) exited = true;
      if (nextId != null && nextId != prevId) entered = true;
      _currentId = nextId;
    }

    return (zone: resolved, entered: entered, exited: exited);
  }

  void reset() {
    _currentId = null;
  }
}
