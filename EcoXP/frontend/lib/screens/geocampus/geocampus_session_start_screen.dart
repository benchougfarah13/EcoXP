import 'package:eco_collect/constants/kenums.dart';
import 'package:eco_collect/constants/ktheme.dart';
import 'package:eco_collect/models/geocampus_campus_zone.dart';
import 'package:eco_collect/providers/level_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/screens/geocampus/campus_map_overview.dart';
import 'package:eco_collect/screens/global/global_bottom_nav.dart';
import 'package:eco_collect/screens/profile/widgets/user_avatar.dart';
import 'package:eco_collect/services/geocampus_local_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// After login: live map + avatar, then one tap enters the full campus game shell.
class GeocampusSessionStartScreen extends StatefulWidget {
  const GeocampusSessionStartScreen({super.key});

  @override
  State<GeocampusSessionStartScreen> createState() =>
      _GeocampusSessionStartScreenState();
}

class _GeocampusSessionStartScreenState extends State<GeocampusSessionStartScreen> {
  Map<String, int> _zoneHealth = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<UserDataProvider>().getUserData;
      final level = context.read<LevelProvider>();
      if (user != null) {
        level.setPlayerCurrentTrophiesTierLevel = user.trophies;
      }
    });
  }

  Future<void> _loadMap() async {
    final health = <String, int>{};
    for (final z in GeocampusCampusZone.campusDefaults) {
      final b = await GeocampusLocalState.zoneBoost(z.id);
      health[z.id] = (z.baseHealth + b).clamp(0, 100);
    }
    if (!mounted) return;
    setState(() {
      _zoneHealth = health;
      _loading = false;
    });
  }

  static String _guardianTitle(KenumTiers tier) {
    if (tier == KenumTiers.loading || tier == KenumTiers.wood) {
      return 'Eco Initiate';
    }
    if (tier.index >= KenumTiers.hero.index) return 'Campus Legend';
    if (tier.index >= KenumTiers.silver1.index) return 'Eco Ambassador';
    if (tier.index >= KenumTiers.bronze1.index) return 'Eco Guardian';
    return 'Eco Initiate';
  }

  void _enterCampusGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const GlobalBottomNav(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: KTheme.globalScaffoldBG,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: KTheme.globalScaffoldBG,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'GeoCampus',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start on the map with your avatar, then explore, scan, and play campus missions.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              CampusMapOverview(
                zoneHealth: _zoneHealth,
                height: 228,
                onZoneTap: (id) async {
                  await GeocampusLocalState.setPreferredZone(id);
                  if (!context.mounted) return;
                  var name = id;
                  for (final z in GeocampusCampusZone.campusDefaults) {
                    if (z.id == id) {
                      name = z.name;
                      break;
                    }
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$name set as your focus zone — scans there boost this area ✦',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Consumer2<UserDataProvider, LevelProvider>(
                builder: (context, userP, levelP, _) {
                  final u = userP.getUserData;
                  if (u == null) return const SizedBox.shrink();
                  final tier = levelP
                      .getPlayerCurrentHeroLevelData(
                        currentTrophies: u.trophies,
                      )
                      .tier;
                  final title = _guardianTitle(tier);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        userData: u,
                        levelProvider: levelP,
                        avatarRadius: 58,
                        isBadgeVisible: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                color: KTheme.superLightBg.withOpacity(0.95),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.my_location,
                                      size: 18, color: Colors.lightGreenAccent),
                                  label: const Text('Campus GPS ready'),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.hiking,
                                      size: 18, color: Colors.amber),
                                  label: const Text('Physical explore mode'),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KTheme.lightBg,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _enterCampusGame,
                child: const Text(
                  'Enter campus · missions & games',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Next: Campus tab keeps this map, plant scan, and mini-games tied to the same XP and trophies.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
