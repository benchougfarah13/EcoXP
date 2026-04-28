import 'package:eco_collect/models/showcase_model.dart';
import 'package:eco_collect/models/user_data_model.dart';
import 'package:eco_collect/utils/common_functions.dart';
import 'package:flutter/material.dart';

class KStrings {
  static const String appTitle = 'GeoCampus';
  static const String logoutMessage =
      'Are you sure you want to log out? Remember, every moment counts in our journey towards a sustainable future. Your contributions make a difference! Come back soon to continue making an impact.';
  static const String defaultVideoUrl =
      'https://youtu.be/80biIVdUkzM?si=KwIQ9ljdNx2OGVd0';
  static const String defaultUsername = 'mother_earth';
  static const String defaultName = 'Mother Earth';

  // NOTE: For Demo purpose let it be here, else put this in .env file.
  static const String secretKey = 'King Rittik';

  // Donation
  static const String donationLink =
      'https://www.globalcitizen.org/en/involved/donate/';

  // Game Android Link
  static const String gameAndroidLink =
      'https://github.com/RittikSoni/Mother-Earth/releases';

  // Functional things
  static final dummyUserData = UserDataModel(
      fullName: 'Loading',
      username: 'Loading',
      xp: 0,
      trophies: 0,
      email: 'Loading',
      country: 'Loading',
      isBanned: false,
      banReason: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now());

  static const String disclaimer =
      "All assets, videos, and content used in this game are for educational purposes only. No copyright infringement is intended. The use of these materials is solely for the purpose of educating players about environmental issues and promoting awareness and action towards a sustainable future.";
}

class KShowcaseData {
  // ___________________________________________________
  // APP BAR THINGS
  // ___________________________________________________
  static final ShowcaseModel appBarBadge = ShowcaseModel(
    key: GlobalKey(),
    title: 'Badge',
    description: 'Unlock badges by completing tasks! 🏅',
  );
  static final ShowcaseModel appBarProfile = ShowcaseModel(
    key: GlobalKey(),
    title: 'Profile',
    description:
        'Check out your profile for options like 💳 Google Wallet integration, 📈 level tracking, 🏆 trophies, and more!',
  );

  // ___________________________________________________
  // TASK SUBMISSION SCREEN
  // ___________________________________________________
  static final ShowcaseModel youtubeLinkTextField = ShowcaseModel(
    key: GlobalKey(),
    title: 'Public Youtube link',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "ここで、あなたのタスクのYouTubeリンクを共有してください！ 📹✨"
        : "Share your task's YouTube link right here! 📹✨",
  );
  static final ShowcaseModel messageToWorldTextField = ShowcaseModel(
    key: GlobalKey(),
    title: 'Message to the world.',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "このビデオを通じて、あなたの力強いメッセージを世界に広めましょう。 🌍✨ あなたの声を聞かせ、ポジティブな変化を起こしましょう！"
        : 'Share your powerful message with the world through this video.🌍✨ Let your voice be heard and inspire positive change!',
  );
  static final ShowcaseModel beAHeroCheck = ShowcaseModel(
    key: GlobalKey(),
    title: 'Be a hero! 🗡️',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "ヒーローになろう！ ✨ このチェックボックスをオンにすると、あなたのビデオが世界中の何百万人もの人に届き、あなたのメッセージが広く伝わります。一緒に変化を起こしましょう！ 🌍"
        : "Be a hero! ✨ By checking this box, your video will reach millions worldwide, spreading your message far and wide. Let's make a difference together! 🌍",
  );
  static final ShowcaseModel submitTaskButton = ShowcaseModel(
    key: GlobalKey(),
    title: '& Submit!',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "準備ができたら、送信をクリックしてください！私たちのチームがあなたのビデオを確認し、タスクと一致していることを確認します。確認後、報酬を受け取ることができます！さらに、ヒーローになることを選択すると、あなたのビデオが世界中の何百万人もの人に見られるでしょう！ 🌟🌍"
        : "Once you're ready, hit submit! Our team will review your video to ensure it aligns with the task. Once verified, you can claim your rewards! Plus, if you choose to be a hero, your video will be seen by millions worldwide! 🌟🌍",
  );

  // ___________________________________________________
  // USER PROFILE
  // ___________________________________________________
  static final ShowcaseModel userProfileCircleAvatar = ShowcaseModel(
    key: GlobalKey(),
    title: 'Level',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "現在のレベルをチェックしましょう！タスクを完了してレベルアップし、新しい実績を解除しましょう！ 🚀🎮"
        : "Check out your current level! Complete tasks to level up and unlock new achievements! 🚀🎮",
  );
  static final ShowcaseModel userProfileGoogleWallet = ShowcaseModel(
    key: GlobalKey(),
    title: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? 'Googleウォレットを使って簡単に他の人とつながろう！ 💳💬'
        : 'Easily connect with others using Google Wallet! 💳💬',
    description: Commonfunctions.getLanguageCodes().languageCode == 'jp'
        ? "これで、Googleウォレットを使用して他の人とプロフィールを共有または保存できます（利用可能な場合）！ 🌍💳 他の人と簡単につながり、あなたの成果を簡単に紹介できます！"
        : "Now, you can share or save your profile with others using Google Wallet (if available in your country)! 🌍💳 Connect with others and showcase your achievements effortlessly!",
  );
}
