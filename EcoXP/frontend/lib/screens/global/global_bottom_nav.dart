import 'package:eco_collect/providers/audio_provider.dart';
import 'package:eco_collect/screens/geocampus/campus_hub_screen.dart';
import 'package:eco_collect/screens/geocampus_map.dart';
import 'package:eco_collect/screens/geocampus_simulation.dart';
import 'package:eco_collect/screens/gameplay/solo/solo_gameplay_screen.dart';
import 'package:eco_collect/screens/explore/explore.dart';
import 'package:eco_collect/screens/global/widgets/bottom_nav_widget.dart';
import 'package:eco_collect/screens/global/global_app_bar.dart';

import 'package:eco_collect/screens/leaderboard/leaderboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

class GlobalBottomNav extends StatefulWidget {
  const GlobalBottomNav({super.key});

  @override
  State<GlobalBottomNav> createState() => _GlobalBottomNavState();
}

class _GlobalBottomNavState extends State<GlobalBottomNav> with WidgetsBindingObserver {
  int activeTabIndex = 0;
  final List<Widget> _screens = [
    const CampusHubScreen(),
    const GeoCampusMapScreen(),
    const GeoCampusSimulationScreen(),
    const SoloGameplayScreen(),
    const Leaderboard(),
    const Explore(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      audioProvider.pauseSound();
    } else if (state == AppLifecycleState.resumed) {
      audioProvider.resumeSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (ctx) {
        return Scaffold(
          bottomNavigationBar: BottomNavWidget(
            onTapTab: (p0) {
              setState(() {
                activeTabIndex = p0;
              });
            },
            currentActiveIndex: activeTabIndex,
          ),
          appBar: globalAppBar(ctx),
          body: _screens[activeTabIndex],
        );
      },
    );
  }
}
