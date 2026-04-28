import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single plant point-of-interest on the campus map.
class CampusPlant {
  final String id;
  final String commonName;
  final String scientificName;
  LatLng? position; // null until the user actually scans this plant
  bool discovered;
  String? scanImageUrl; // PlantNet returned image URL (optional)
  double? confidence;

  CampusPlant({
    required this.id,
    required this.commonName,
    required this.scientificName,
    this.position,
    this.discovered = false,
    this.scanImageUrl,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'commonName': commonName,
        'scientificName': scientificName,
        'lat': position?.latitude,
        'lng': position?.longitude,
        'discovered': discovered,
        'scanImageUrl': scanImageUrl,
        'confidence': confidence,
      };

  factory CampusPlant.fromJson(Map<String, dynamic> j) => CampusPlant(
        id: j['id'],
        commonName: j['commonName'],
        scientificName: j['scientificName'],
        position: j['lat'] != null && j['lng'] != null
            ? LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble())
            : null,
        discovered: j['discovered'] ?? false,
        scanImageUrl: j['scanImageUrl'],
        confidence: j['confidence']?.toDouble(),
      );
}

class PlantMapProvider extends ChangeNotifier {
  static const _kKey = 'campus_plants_v2'; // bumped version to force reload

  List<CampusPlant> _plants = [];
  List<CampusPlant> get plants => _plants;

  Set<String> _unlockedSpecies = {};
  Set<String> get unlockedSpecies => _unlockedSpecies;

  int get totalDiscovered => _plants.where((p) => p.discovered).length;

  bool isSpeciesNew(String scientificName) {
    return !_unlockedSpecies.contains(scientificName);
  }

  Future<void> markSpeciesUnlocked(String scientificName) async {
    _unlockedSpecies.add(scientificName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_kKey}_pokedex', _unlockedSpecies.toList());
    notifyListeners();
  }

  // ── Campus plant list — positions are null until the player scans each one ──
  static final List<CampusPlant> _defaults = [
    CampusPlant(id: 'boug_white',          commonName: 'Bougainvillea White',           scientificName: 'Bougainvillea spectabilis'),
    CampusPlant(id: 'boug_magenta',        commonName: 'Bougainvillea Magenta',          scientificName: 'Bougainvillea glabra'),
    CampusPlant(id: 'boug_rosenka',        commonName: "Bougainvillea 'Rosenka'",        scientificName: "Bougainvillea × buttiana 'Rosenka'"),
    CampusPlant(id: 'boug_enid',           commonName: "Bougainvillea 'Enid Lancaster'", scientificName: "Bougainvillea × buttiana 'Enid Lancaster'"),
    CampusPlant(id: 'yellow_oleander',     commonName: 'Yellow Oleander',                scientificName: 'Cascabela thevetia'),
    CampusPlant(id: 'oxalis',              commonName: 'Oxalis corniculata',             scientificName: 'Oxalis corniculata'),
    CampusPlant(id: 'palm_1',             commonName: 'Date Palm',                      scientificName: 'Phoenix dactylifera'),
    CampusPlant(id: 'platycladus',         commonName: 'Oriental Arborvitae',            scientificName: 'Platycladus orientalis'),
    CampusPlant(id: 'austrocylindropuntia',commonName: "Eve's Needle Cactus",            scientificName: 'Austrocylindropuntia subulata'),
    CampusPlant(id: 'agave',              commonName: "Agave 'Variegata'",              scientificName: "Agave desmetiana 'Variegata'"),
    CampusPlant(id: 'plumbago_alba',       commonName: 'White Plumbago',                 scientificName: 'Plumbago auriculata f. alba'),
    CampusPlant(id: 'olive_1',            commonName: 'Olive Tree',                     scientificName: 'Olea europaea'),
    CampusPlant(id: 'lantana_nivea',       commonName: "Lantana 'Nivea'",               scientificName: "Lantana camara 'Nivea'"),
    CampusPlant(id: 'lantana_mutabilis',   commonName: "Lantana 'Mutabilis'",           scientificName: "Lantana camara 'Mutabilis'"),
    CampusPlant(id: 'jacobaea',            commonName: 'Silver Ragwort',                 scientificName: 'Jacobaea maritima'),
    CampusPlant(id: 'hibiscus',           commonName: 'Hibiscus',                       scientificName: 'Hibiscus rosa-sinensis'),
    CampusPlant(id: 'jasmine_1',          commonName: 'Spanish Jasmine',                scientificName: 'Jasminum grandiflorum'),
    CampusPlant(id: 'euryops',            commonName: "Bush Daisy 'Viridis'",           scientificName: "Euryops pectinatus 'Viridis'"),
    CampusPlant(id: 'ficus_benjamina',     commonName: 'Weeping Fig',                    scientificName: "Ficus benjamina 'Variegated White'"),
    CampusPlant(id: 'parkinsonia',         commonName: 'Jerusalem Thorn',                scientificName: 'Parkinsonia aculeata'),
    CampusPlant(id: 'yucca',              commonName: 'Spanish Dagger',                 scientificName: 'Yucca gloriosa'),
    CampusPlant(id: 'araucaria',          commonName: 'Norfolk Island Pine',            scientificName: 'Araucaria heterophylla'),
    CampusPlant(id: 'fig_1',             commonName: 'Common Fig',                     scientificName: 'Ficus carica'),
    CampusPlant(id: 'emilia',             commonName: 'Emilia',                         scientificName: 'Emilia sonchifolia'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load unlocked Pokedex database
    final unlocked = prefs.getStringList('${_kKey}_pokedex');
    if (unlocked != null) {
      _unlockedSpecies = unlocked.toSet();
    }

    final raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        final List decoded = jsonDecode(raw);
        _plants = decoded.map((e) => CampusPlant.fromJson(e)).toList();
      } catch (_) {
        _plants = List.from(_defaults);
      }
    } else {
      _plants = List.from(_defaults);
    }
    notifyListeners();
  }

  Future<void> markDiscovered({
    required String plantId,
    required String commonName,
    required String scientificName,
    LatLng? position,
    double? confidence,
    String? imageUrl,
  }) async {
    final idx = _plants.indexWhere((p) => p.id == plantId);
    if (idx != -1) {
      _plants[idx] = CampusPlant(
        id: _plants[idx].id,
        commonName: commonName.isNotEmpty ? commonName : _plants[idx].commonName,
        scientificName: scientificName.isNotEmpty ? scientificName : _plants[idx].scientificName,
        position: position ?? _plants[idx].position,
        discovered: true,
        confidence: confidence,
        scanImageUrl: imageUrl,
      );
    }
    notifyListeners();
    await _persist();
  }

  /// Call after a successful PlantNet scan at the player's current GPS position.
  /// Adds an ad-hoc discovered plant if the player isn't near any pre-seeded one.
  Future<void> addFreeDiscovery({
    required LatLng position,
    required String commonName,
    required String scientificName,
    double? confidence,
    String? imageUrl,
  }) async {
    final id = 'free_${DateTime.now().millisecondsSinceEpoch}';
    _plants.add(CampusPlant(
      id: id,
      commonName: commonName,
      scientificName: scientificName,
      position: position,
      discovered: true,
      confidence: confidence,
      scanImageUrl: imageUrl,
    ));
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(_plants.map((p) => p.toJson()).toList()));
  }

  void reset() {
    _plants = List.from(_defaults);
    notifyListeners();
    _persist();
  }
}
