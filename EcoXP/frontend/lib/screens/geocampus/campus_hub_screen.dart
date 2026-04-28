import 'package:eco_collect/constants/kenums.dart';
import 'package:eco_collect/mini_games/mini_games.dart';
import 'package:eco_collect/routes/kroutes.dart';
import 'package:eco_collect/services/audio_services.dart';
import 'package:eco_collect/services/geocampus_local_state.dart';
import 'package:eco_collect/providers/level_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/screens/profile/widgets/user_avatar.dart';
import 'package:eco_collect/models/user_data_model.dart';
import 'package:eco_collect/components/reusable_bg_image.dart';
import 'package:eco_collect/constants/kassets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter

class CampusHubScreen extends StatefulWidget {
  const CampusHubScreen({super.key});

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen> {
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    AudioServices.playAudioAccordingToScreen(KenumScreens.home);
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<UserDataProvider>().getUserData;
      final level = context.read<LevelProvider>();
      if (user != null) {
        level.setPlayerCurrentTrophiesTierLevel = user.trophies;
      }
    });
  }

  Future<void> _reload() async {
    final streak = await GeocampusLocalState.rollStreakIfNeeded();
    if (!mounted) return;
    setState(() {
      _streak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Campus Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // The requested vegetation background
          const ReusableBgImage(
            assetImageSource: KImages.forest,
          ),
          // Dark overlay to maintain readability of the white glassmorphic UI
          Container(
            color: Colors.black.withOpacity(0.4),
            width: double.infinity,
            height: double.infinity,
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Top Avatar & Stats Area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 20, bottom: 40),
                      child: Consumer2<UserDataProvider, LevelProvider>(
                        builder: (context, userP, levelP, _) {
                          final u = userP.getUserData ?? UserDataModel(
                            fullName: 'Eco Hero', username: 'hero', email: '', xp: 82177, trophies: 197680,
                            country: 'HQ', isBanned: false, banReason: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
                          );

                          return Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)
                                  ],
                                ),
                                child: UserAvatar(userData: u, levelProvider: levelP, avatarRadius: 55),
                              ),
                              const SizedBox(height: 16),
                              Text('@${u.username}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 4),
                              const Text('Senior Preservationist', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                              
                              const SizedBox(height: 30),
                              
                              // Action/Stat Row - Glassmorphism style
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(child: _buildGlassCard('XP', u.xp.toString(), Icons.moving_rounded, Colors.blueAccent)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGlassCard('Eco Coins', u.trophies.toString(), Icons.eco, Colors.greenAccent)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGlassCard('Streak', '${_streak}d', Icons.local_fire_department, Colors.orangeAccent)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Content Body
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // How to earn Coins explanation
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black45, // Translucent black
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, color: Colors.greenAccent, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Scan real-world campus plants to earn Eco Coins & unlock the Encyclopedia!',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // REAL WORLD DATA PANEL - Glassmorphism
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), shape: BoxShape.circle),
                                          child: const Icon(Icons.public, color: Colors.greenAccent),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text('Global Ecological Crisis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Verified data sourced from the FAO & IPBES reports (2020-2023). Our real-world vegetation is vanishing.',
                                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildPremiumDataRow('Deforestation Rate', '10M ha/year', Icons.trending_down, Colors.greenAccent),
                                    const Divider(height: 24, color: Colors.white24),
                                    _buildPremiumDataRow('Total Forests Lost (Since 1990)', '420 Million ha', Icons.forest, Colors.orangeAccent),
                                    const Divider(height: 24, color: Colors.white24),
                                    _buildPremiumDataRow('Species Threatened w/ Extinction', '1 Million+', Icons.pets, Colors.purpleAccent),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Minigames Banner
                          GestureDetector(
                            onTap: () {
                              KRoute.push(context: context, page: const MiniGames());
                            },
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(Icons.videogame_asset, size: 120, color: Colors.white.withOpacity(0.15)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Text('Play Minigames', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                                            Text('Save trees & earn extra XP', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                          ],
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.chevron_right, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // padding for bottom nav
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(String title, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDataRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        ),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
