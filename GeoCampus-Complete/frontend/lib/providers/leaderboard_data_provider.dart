import 'package:eco_collect/api/firebase_apis.dart';
import 'package:eco_collect/models/user_data_model.dart';
import 'package:flutter/material.dart';

class LeaderboardDataProvider extends ChangeNotifier {
  List<UserDataModel>? leaderBoardData;

  void fetchLeaderBoardData() async {
    leaderBoardData = await FirebaseApis().fetchTopRankedPlayersByXP();
    notifyListeners();
  }
}
