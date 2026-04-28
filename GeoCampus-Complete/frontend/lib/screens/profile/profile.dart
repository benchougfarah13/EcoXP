import 'dart:io';

import 'package:eco_collect/api/firebase_apis.dart';
import 'package:eco_collect/components/buttons/reusable_button.dart';
import 'package:eco_collect/components/reusable_app_bar.dart';
import 'package:eco_collect/components/reusable_bg_image.dart';
import 'package:eco_collect/constants/kassets.dart';
import 'package:eco_collect/constants/kenums.dart';
import 'package:eco_collect/constants/kshowcase_keys.dart';
import 'package:eco_collect/constants/kstrings.dart';
import 'package:eco_collect/constants/ktheme.dart';

import 'package:eco_collect/providers/level_provider.dart';
import 'package:eco_collect/providers/user_provider.dart';
import 'package:eco_collect/screens/google_wallet/google_wallet_things.dart';
import 'package:eco_collect/screens/profile/widgets/user_avatar.dart';
import 'package:eco_collect/screens/profile/widgets/user_details.dart';
import 'package:eco_collect/services/audio_services.dart';
import 'package:eco_collect/services/showcase_services.dart';
import 'package:eco_collect/utils/common_functions.dart';
import 'package:eco_collect/utils/kloading.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    AudioServices.playAudioAccordingToScreen(KenumScreens.userProfile);
    return Scaffold(
      appBar: reusableAppBar(
        title: 'Hero Profile',
      ),
      body: Consumer2<UserDataProvider, LevelProvider>(
        builder: (ctx, userProvider, levelProvider, child) => ShowCaseWidget(
          builder: (context) {
          ShowcaseServices().startShowCase(
            context: context,
            screen: KenumScreens.userProfile,
          );
              return Stack(
                children: [
                  const ReusableBgImage(
                    assetImageSource: KLottie.campfireGuyWithGuitar,
                    repeatLottie: false,
                    isLottie: true,
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0)
                          .copyWith(bottom: 70.0),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Hero(
                              tag: 'heroProfile',
                              child: Showcase(
                                key: KShowcaseKeys.circleAvatarKey,
                                title:
                                    KShowcaseData.userProfileCircleAvatar.title,
                                description: KShowcaseData
                                    .userProfileCircleAvatar.description,
                                child: UserAvatar(
                                  userData: userProvider.getUserData ??
                                      KStrings.dummyUserData,
                                  levelProvider: levelProvider,
                                ),
                              )),
                          const SizedBox.shrink(),
                          Commonfunctions.gapMultiplier(),
                          UserDetails(
                            userDetails: userProvider.getUserData ??
                                KStrings.dummyUserData,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReusableButton(
                          label: 'Logout',
                          onTap: () async {
                            KLoadingToast.showCharacterDialog(
                              title: 'Logout?',
                              message: KStrings.logoutMessage,
                              explorerImage: KExplorers.explorer7,
                              secondaryLabel: 'Cancel',
                              onSecondaryPressed: () async {
                                Navigator.pop(context);
                              },
                              primaryLabel: 'Logout',
                              onPrimaryPressed: () async {
                                await FirebaseApis.logout();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
      ),
    );
  }
}
