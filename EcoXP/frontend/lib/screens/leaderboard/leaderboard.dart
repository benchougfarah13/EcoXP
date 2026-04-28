import 'package:eco_collect/components/reusable_bg_image.dart';
import 'package:eco_collect/components/reusable_top_character_dialogue.dart';
import 'package:eco_collect/constants/kassets.dart';
import 'package:eco_collect/constants/kenums.dart';
import 'package:eco_collect/constants/ktheme.dart';
import 'package:eco_collect/providers/leaderboard_data_provider.dart';
import 'package:eco_collect/services/audio_services.dart';
import 'package:eco_collect/utils/common_functions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    AudioServices.playAudioAccordingToScreen(KenumScreens.hero);
    return SafeArea(
      child: Stack(
        children: [
          const ReusableBgImage(
            assetImageSource: KLottie.forest,
            isLottie: true,
            repeatLottie: false,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const ReusableTopCharacterDialogue(
                  message:
                      "Only the most dedicated protectors of the campus rise to these ranks. Are you ready to claim your place among the Elite?",
                  explorerImagePath: KExplorers.explorer4,
                ),
                Commonfunctions.gapMultiplier(gapMultiplier: 0.5),
                Consumer<LeaderboardDataProvider>(
                  builder: (context, leaderBoardProvider, child) {
                    if (leaderBoardProvider.leaderBoardData == null) {
                      leaderBoardProvider.fetchLeaderBoardData();
                      return Center(
                        child: LottieBuilder.asset(
                          KLottie.loading,
                          height: 80,
                        ),
                      );
                    }

                    final players = leaderBoardProvider.leaderBoardData!;

                    return Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          leaderBoardProvider.fetchLeaderBoardData();
                        },
                        child: ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final rank = index + 1;

                            if (index < 3) {
                              return _buildPodiumTile(context, player, rank);
                            }

                            return _buildRankTile(context, player, rank);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumTile(BuildContext context, player, int rank) {
    Color medalColor;
    String rankSuffix;
    switch (rank) {
      case 1:
        medalColor = Colors.amber;
        rankSuffix = "st";
        break;
      case 2:
        medalColor = Colors.grey[300]!;
        rankSuffix = "nd";
        break;
      default:
        medalColor = Colors.brown[300]!;
        rankSuffix = "rd";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: medalColor.withOpacity(0.5), width: 2),
        gradient: LinearGradient(
          colors: [
            KTheme.transparencyBlack,
            medalColor.withOpacity(0.1),
          ],
        ),
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield, color: medalColor, size: 50),
            Text(
              "$rank",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18),
            ),
          ],
        ),
        title: Text(
          player.fullName ?? "Anonymous Hero",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          "@${player.username}",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${player.xp} XP",
              style: TextStyle(
                  color: medalColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Ranked $rank$rankSuffix",
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankTile(BuildContext context, player, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: KTheme.transparencyBlack,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Text(
            "#$rank",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        title: Text(
          player.fullName ?? "Protector",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "@${player.username}",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: Text(
          "${player.xp} XP",
          style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ),
    );
  }
}
