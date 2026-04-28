import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eco_collect/api/firebase_apis.dart';
import 'package:eco_collect/components/error_app.dart';
import 'package:eco_collect/constants/kstrings.dart';
import 'package:eco_collect/constants/ktheme.dart';
import 'package:eco_collect/main.dart';

import 'package:eco_collect/models/user_data_model.dart';
import 'package:eco_collect/providers/audio_provider.dart';
import 'package:eco_collect/providers/game_state_provider.dart';
import 'package:eco_collect/providers/leaderboard_data_provider.dart';
import 'package:eco_collect/providers/level_provider.dart';
import 'package:eco_collect/providers/message_configs_provider.dart';
import 'package:eco_collect/providers/solo_level_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/providers/plant_map_provider.dart';
import 'package:eco_collect/routes/kroutes.dart';
import 'package:eco_collect/screens/auth/auth_home.dart';
import 'package:page_transition/page_transition.dart';

import 'package:eco_collect/screens/geocampus/geocampus_session_start_screen.dart';
import 'package:eco_collect/utils/common_functions.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LeaderboardDataProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MessageConfigProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserDataProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LevelProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SoloLevelProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => GameStateProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlantMapProvider(),
        ),
      ],
      builder: (context, child) => MaterialApp(
        title: KStrings.appTitle,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: KTheme.globalScaffoldBG,
            appBarTheme: const AppBarTheme(
              backgroundColor: KTheme.globalAppBarBG,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              fillColor: KTheme.transparencyBlack,
              errorStyle:
                  TextStyle(color: KTheme.error, fontWeight: FontWeight.bold),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: KTheme.globalScaffoldBG,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)),
        navigatorKey: navigatorKey,
        home: AnimatedSplashScreen(
          backgroundColor: const Color(0xFF071A0F),
          splash: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF2D6A4F), Color(0xFF071A0F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF40916C).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF95D5B2),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'GEOCAMPUS',
                  style: TextStyle(
                    color: Color(0xFF95D5B2),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EXPLORE  ·  SCAN  ·  PROTECT',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF40916C)),
                  ),
                ),
              ],
            ),
          ),
          nextScreen: const MainGameEntry(),
          duration: 3000,
          splashTransition: SplashTransition.fadeTransition,
          pageTransitionType: PageTransitionType.fade,
        ),
      ),
    );
  }
}

class MainGameEntry extends StatelessWidget {
  const MainGameEntry({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserDataModel>(
      future: FirebaseApis().getSavedUserData(context),
      builder: (BuildContext context, AsyncSnapshot<UserDataModel> snapshot) {
        if (snapshot.hasError) {
          return ErrorApp(
            onRetry: () async {
              await FirebaseApis.logout();
              main();
            },
            retryLabel: 'Re-login',
          );
        } else if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.data!.username != '') {
          /// LOGGED IN USER

          return const GeocampusSessionStartScreen();
        }

        return const AuthHome();
      },
    );
  }
}
