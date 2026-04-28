import 'package:eco_collect/constants/ktheme.dart';
import 'package:flutter/material.dart';

class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget(
      {super.key, required this.onTapTab, required this.currentActiveIndex});
  final Function(int) onTapTab;
  final int currentActiveIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617), // Matches standard dark background
        border: Border(
          top: BorderSide(color: Colors.blueAccent.withOpacity(0.1), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 28),
              label: 'HUB',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded, size: 24),
              activeIcon: Icon(Icons.map_rounded, size: 28),
              label: 'MAP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.park_rounded, size: 24),
              activeIcon: Icon(Icons.park_rounded, size: 28),
              label: 'SIMULATION',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports_rounded, size: 24),
              activeIcon: Icon(Icons.sports_esports_rounded, size: 28),
              label: 'PLAY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded, size: 24),
              activeIcon: Icon(Icons.emoji_events_rounded, size: 28),
              label: 'RANKS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded, size: 24),
              activeIcon: Icon(Icons.settings_rounded, size: 28),
              label: 'MORE',
            ),
          ],
          onTap: onTapTab,
          currentIndex: currentActiveIndex,
        ),
    );
  }
}
