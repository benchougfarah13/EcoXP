import 'package:flutter/material.dart';

/// A faculty / green zone on the live campus health map.
class GeocampusCampusZone {
  const GeocampusCampusZone({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.baseHealth,
    required this.accent,
  });

  final String id;
  final String name;
  final String subtitle;
  /// Seed health (0–100) before player impact is applied.
  final int baseHealth;
  final Color accent;

  static const List<GeocampusCampusZone> campusDefaults = [
    GeocampusCampusZone(
      id: 'quad',
      name: 'Central Quad',
      subtitle: 'Green core · events',
      baseHealth: 72,
      accent: Color(0xFF2D6A4F),
    ),
    GeocampusCampusZone(
      id: 'eng',
      name: 'Engineering Grove',
      subtitle: 'Tree cover · bike lane',
      baseHealth: 64,
      accent: Color(0xFF40916C),
    ),
    GeocampusCampusZone(
      id: 'sci',
      name: 'Science Walk',
      subtitle: 'Labs · planters',
      baseHealth: 58,
      accent: Color(0xFF52B788),
    ),
    GeocampusCampusZone(
      id: 'lib',
      name: 'Library Gardens',
      subtitle: 'Quiet biodiversity',
      baseHealth: 81,
      accent: Color(0xFF74C69D),
    ),
    GeocampusCampusZone(
      id: 'dorms',
      name: 'Residence Courtyards',
      subtitle: 'Community compost',
      baseHealth: 55,
      accent: Color(0xFF95D5B2),
    ),
    GeocampusCampusZone(
      id: 'sports',
      name: 'Athletics Edge',
      subtitle: 'Heat island buffer',
      baseHealth: 49,
      accent: Color(0xFFB7E4C7),
    ),
  ];
}
