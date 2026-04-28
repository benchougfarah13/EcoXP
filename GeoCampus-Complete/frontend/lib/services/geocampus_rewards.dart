import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_collect/api/firebase_apis.dart';
import 'package:eco_collect/providers/level_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/utils/kloading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Awards XP and trophies into the same Firestore path as solo mission rewards.
class GeocampusRewards {
  GeocampusRewards._();

  static Future<void> grantExplorationReward(
    BuildContext context, {
    required int xp,
    required int trophies,
  }) async {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    final ud = userProvider.getUserData;
    final username = ud?.username;
    if (username == null || username.isEmpty || !context.mounted) {
      return;
    }

    try {
      KLoadingToast.startLoading();
      await FirebaseFirestore.instance
          .collection('users')
          .doc('endUsers')
          .collection('endUsersData')
          .doc(username)
          .update({
        'trophies': ud!.trophies + trophies,
        'xp': ud.xp + xp,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!context.mounted) return;
      await FirebaseApis().fetchLatestUserData(
        context: context,
        username: username,
        emailAddress: ud.email,
      );

      if (!context.mounted) return;
      final levelProvider = Provider.of<LevelProvider>(context, listen: false);
      final fresh = userProvider.getUserData;
      if (fresh != null) {
        levelProvider.setPlayerCurrentTrophiesTierLevel = fresh.trophies;
      }
    } catch (_) {
      if (context.mounted) {
        KLoadingToast.showCustomDialog(
          message: 'Could not sync rewards. Check connection and try again.',
        );
      }
    } finally {
      KLoadingToast.stopLoading();
    }
  }
}
