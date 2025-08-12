import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/constants/string_labels.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/ads.dart';
import 'package:flutterquiz/features/auth/auth_repository.dart';
import 'package:flutterquiz/features/auth/cubits/auth_cubit.dart';
import 'package:flutterquiz/features/auth/cubits/refer_and_earn_cubit.dart';
import 'package:flutterquiz/features/badges/cubits/badges_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/battle_room_cubit.dart';
import 'package:flutterquiz/features/battle_room/cubits/multi_user_battle_room_cubit.dart';
import 'package:flutterquiz/features/exam/cubits/exam_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_local_data_source.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/contest_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/quizzone_category_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/battle/create_or_join_screen.dart';
import 'package:flutterquiz/ui/screens/home/widgets/activity_card.dart';
import 'package:flutterquiz/ui/screens/home/widgets/all.dart';
import 'package:flutterquiz/ui/screens/home/widgets/daily_quote.dart';
import 'package:flutterquiz/ui/screens/home/widgets/learn_and_explore.dart';
import 'package:flutterquiz/ui/screens/profile/create_or_edit_profile_screen.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Route<HomeScreen> route() {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<ReferAndEarnCubit>(
            create: (_) => ReferAndEarnCubit(AuthRepository()),
          ),
          BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (_) =>
                UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
          ),
          BlocProvider<UpdateUserDetailCubit>(
            create: (_) => UpdateUserDetailCubit(ProfileManagementRepository()),
          ),
        ],
        child: const HomeScreen(),
      ),
    );
  }
}

typedef ZoneType = ({
  String title,
  String img,
  String desc,
});

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool get _isGuest => context.read<AuthCubit>().isGuest;

  /// Quiz Zone globals
  int oldCategoriesToShowCount = 0;
  bool isCateListExpanded = false;
  bool canExpandCategoryList = false;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  int _notificationId = 0;

  final battleZones = <ZoneType>[
    (title: 'groupPlay', img: Assets.groupBattleIcon, desc: 'desGroupPlay'),
    (title: 'battleQuiz', img: Assets.oneVsOneIcon, desc: 'desBattleQuiz'),
  ];

  final examZones = <ZoneType>[
    (title: 'exam', img: Assets.examQuizIcon, desc: 'desExam'),
    (
      title: 'selfChallenge',
      img: Assets.selfChallengeIcon,
      desc: 'challengeYourselfLbl'
    ),
  ];

  final todayActivityZones = <ZoneType>[
    (
      title: 'Quiz of the day',
      img: Assets.examQuizIcon,
      desc: '15 Question',
    ),
    (
      title: 'Featured Quiz',
      img: Assets.selfChallengeIcon,
      desc: '12 Question'
    ),
    (title: 'Fun Friday', img: Assets.examQuizIcon, desc: '10 Question'),
  ];

  final learnAndExploreZones = <ZoneType>[
    (
      title: 'Frontend Development',
      img: Assets.dailyQuizBanner,
      desc: 'It is a long established fact that a reader will be...',
    ),
    (
      title: 'Ai',
      img: Assets.dailyQuizBanner,
      desc: 'It is a long established fact that a reader will be...'
    ),
  ];

  final playDifferentZones = <ZoneType>[
    (title: 'dailyQuiz', img: Assets.dailyQuizIcon, desc: 'desDailyQuiz'),
    (title: 'funAndLearn', img: Assets.funNLearnIcon, desc: 'desFunAndLearn'),
    (
      title: 'guessTheWord',
      img: Assets.guessTheWordIcon,
      desc: 'desGuessTheWord'
    ),
    (
      title: 'audioQuestions',
      img: Assets.audioQuizIcon,
      desc: 'desAudioQuestions'
    ),
    (title: 'mathMania', img: Assets.mathsQuizIcon, desc: 'desMathMania'),
    (title: 'truefalse', img: Assets.trueFalseQuizIcon, desc: 'desTrueFalse'),
    (title: 'multiMatch', img: Assets.multiMatchIcon, desc: 'desMultiMatch'),
  ];

  // Screen dimensions
  double get scrWidth => context.width;

  double get scrHeight => context.height;

  // HomeScreen horizontal margin, change from here
  double get hzMargin => scrWidth * UiUtils.hzMarginPct;

  double get _statusBarPadding => MediaQuery.of(context).padding.top;

  // TextStyles
  // check build() method
  late var _boldTextStyle = TextStyle(
    fontWeight: FontWeights.bold,
    fontSize: 18,
    color: Theme.of(context).colorScheme.onTertiary,
  );

  ///
  late String _currLangId;
  late final SystemConfigCubit _sysConfigCubit;
  final _quizZoneId =
      UiUtils.getCategoryTypeNumberFromQuizType(QuizTypes.quizZone);

  @override
  void initState() {
    super.initState();
    showAppUnderMaintenanceDialog();
    setQuizMenu();
    _initLocalNotification();
    checkForUpdates();
    setupInteractedMessage();

    /// Create Ads
    Future.delayed(Duration.zero, () async {
      await context.read<RewardedAdCubit>().createDailyRewardAd(context);
      context.read<InterstitialAdCubit>().createInterstitialAd(context);
    });

    WidgetsBinding.instance.addObserver(this);

    ///
    _currLangId = UiUtils.getCurrentQuizLanguageId(context);
    _sysConfigCubit = context.read<SystemConfigCubit>();
    final quizCubit = context.read<QuizCategoryCubit>();
    final quizZoneCubit = context.read<QuizoneCategoryCubit>();

    if (_isGuest) {
      quizCubit.getQuizCategory(languageId: _currLangId, type: _quizZoneId);
      quizZoneCubit.getQuizCategory(languageId: _currLangId);
    } else {
      fetchUserDetails();

      quizCubit.getQuizCategoryWithUserId(
        languageId: _currLangId,
        type: _quizZoneId,
      );
      quizZoneCubit.getQuizCategoryWithUserId(languageId: _currLangId);
      context.read<ContestCubit>().getContest(languageId: _currLangId);
    }
  }

  void showAppUnderMaintenanceDialog() {
    Future.delayed(Duration.zero, () {
      if (_sysConfigCubit.isAppUnderMaintenance) {
        showDialog<void>(
          context: context,
          builder: (_) => const AppUnderMaintenanceDialog(),
        );
      }
    });
  }

  Future<void> _initLocalNotification() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onTapLocalNotification,
    );

    /// Request Permissions for IOS
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions();
    }
  }

  void setQuizMenu() {
    Future.delayed(Duration.zero, () {
      if (!_sysConfigCubit.isDailyQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'dailyQuiz');
      }

      if (!_sysConfigCubit.isTrueFalseQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'truefalse');
      }

      if (!_sysConfigCubit.isFunNLearnEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'funAndLearn');
      }

      if (!_sysConfigCubit.isGuessTheWordEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'guessTheWord');
      }

      if (!_sysConfigCubit.isAudioQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'audioQuestions');
      }

      if (!_sysConfigCubit.isMathQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'mathMania');
      }

      if (!_sysConfigCubit.isExamQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'exam');
      }

      if (!_sysConfigCubit.isSelfChallengeQuizEnabled) {
        examZones.removeWhere((e) => e.title == 'selfChallenge');
      }

      if (!_sysConfigCubit.isGroupBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'groupPlay');
      }

      if (!_sysConfigCubit.isOneVsOneBattleEnabled &&
          !_sysConfigCubit.isRandomBattleEnabled) {
        battleZones.removeWhere((e) => e.title == 'battleQuiz');
      }

      if (!_sysConfigCubit.isMultiMatchQuizEnabled) {
        playDifferentZones.removeWhere((e) => e.title == 'multiMatch');
      }
      // if (!_sysConfigCubit.isFunNLearnEnabled) {
      //   playDifferentZones.removeWhere((e) => e.title == 'Quiz of the day');
      // }
      // if (!_sysConfigCubit.isFunNLearnEnabled) {
      //   playDifferentZones.removeWhere((e) => e.title == 'Featured Quiz');
      // }
      // if (!_sysConfigCubit.isFunNLearnEnabled) {
      //   playDifferentZones.removeWhere((e) => e.title == 'Fun Friday');
      // }
      setState(() {});
    });
  }

  late bool showUpdateContainer = false;

  Future<void> checkForUpdates() async {
    await Future<void>.delayed(Duration.zero);
    if (_sysConfigCubit.isForceUpdateEnable) {
      try {
        final forceUpdate =
            await UiUtils.forceUpdate(_sysConfigCubit.appVersion);

        if (forceUpdate) {
          setState(() => showUpdateContainer = true);
        }
      } on Exception catch (e) {
        log('Force Update Error', error: e);
      }
    }
  }

  Future<void> setupInteractedMessage() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        announcement: true,
        provisional: true,
      );
    } else {
      final isGranted = (await Permission.notification.status).isGranted;
      if (!isGranted) await Permission.notification.request();
    }
    await FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // handle background notification
    FirebaseMessaging.onBackgroundMessage(UiUtils.onBackgroundMessage);
    //handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        log('Notification arrives : ${message.toMap()}');
        final data = message.data;
        log(data.toString(), name: 'notification data msg');
        final title = data['title'].toString();
        final body = data['body'].toString();
        final type = data['type'].toString();
        final image = data['image'].toString();

        //if notification type is badges then update badges in cubit list
        if (type == 'badges') {
          Future.delayed(Duration.zero, () {
            context
                .read<BadgesCubit>()
                .unlockBadge(data['badge_type'] as String);
          });
        }

        if (type == 'payment_request') {
          Future.delayed(Duration.zero, () {
            context.read<UserDetailsCubit>().updateCoins(
                  addCoin: true,
                  coins: int.parse(data['coins'] as String),
                );
          });
        }
        log(image, name: 'notification image data');
        //payload is some data you want to pass in local notification
        if (image != 'null' && image.isNotEmpty) {
          log('image ${image.runtimeType}');
          generateImageNotification(title, body, image, type, type);
        } else {
          generateSimpleNotification(title, body, type);
        }
      }
    });
  }

  //quiz_type according to the notification category
  QuizTypes _getQuizTypeFromCategory(String category) {
    return switch (category) {
      'audio-question-category' => QuizTypes.audioQuestions,
      'guess-the-word-category' => QuizTypes.guessTheWord,
      'fun-n-learn-category' => QuizTypes.funAndLearn,
      _ => QuizTypes.quizZone,
    };
  }

  // notification type is category then move to category screen
  Future<void> _handleMessage(RemoteMessage message) async {
    try {
      if (message.data['type'].toString().contains('category')) {
        await Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType':
                _getQuizTypeFromCategory(message.data['type'] as String),
          },
        );
      } else if (message.data['type'] == 'badges') {
        //if user open app by tapping
        UiUtils.updateBadgesLocally(context);
        await Navigator.of(context).pushNamed(Routes.badges);
      } else if (message.data['type'] == 'payment_request') {
        await Navigator.of(context).pushNamed(Routes.wallet);
      }
    } on Exception catch (e) {
      log(e.toString(), error: e);
    }
  }

  Future<void> _onTapLocalNotification(NotificationResponse? payload) async {
    final type = payload!.payload ?? '';
    if (type == 'badges') {
      await Navigator.of(context).pushNamed(Routes.badges);
    } else if (type.contains('category')) {
      await Navigator.of(context).pushNamed(
        Routes.category,
        arguments: {
          'quizType': _getQuizTypeFromCategory(type),
        },
      );
    } else if (type == 'payment_request') {
      await Navigator.of(context).pushNamed(Routes.wallet);
    }
  }

  Future<void> generateImageNotification(
    String title,
    String msg,
    String image,
    String payloads,
    String type,
  ) async {
    final largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
    final bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');
    final bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true,
    );
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      kPackageName,
      kAppName,
      icon: '@drawable/ic_notification',
      channelDescription: kAppName,
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation,
    );
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      _notificationId++,
      title,
      msg,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // notification on foreground
  Future<void> generateSimpleNotification(
    String title,
    String body,
    String payloads,
  ) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      kPackageName, //channel id
      kAppName, //channel name
      channelDescription: kAppName,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@drawable/ic_notification',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      _notificationId++,
      title,
      body,
      platformChannelSpecifics,
      payload: payloads,
    );
  }

  @override
  void dispose() {
    ProfileManagementLocalDataSource().updateReversedCoins(0);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //show you left the game
    if (state == AppLifecycleState.resumed) {
      UiUtils.needToUpdateCoinsLocally(context);
    } else {
      ProfileManagementLocalDataSource().updateReversedCoins(0);
    }
  }

  void _onTapProfile() => context.pushNamed(Routes.menuScreen);

  void _onTapLeaderboard() => Navigator.of(context).pushNamed(
        _isGuest ? Routes.login : Routes.leaderBoard,
      );
  void _onTapDailyTask() => Navigator.of(context).pushNamed(
        _isGuest ? Routes.login : Routes.trueFalse,
      );

  void _onPressedZone(String index) {
    if (_isGuest) {
      _showLoginDialog();
      return;
    }

    switch (index) {
      case 'dailyQuiz':
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.dailyQuiz,
            'numberOfPlayer': 1,
          },
        );
        return;
      case 'funAndLearn':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.funAndLearn,
          },
        );
        return;
      case 'guessTheWord':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.guessTheWord,
          },
        );
        return;
      case 'audioQuestions':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.audioQuestions,
          },
        );
        return;
      case 'mathMania':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.mathMania,
          },
        );
        return;
      case 'truefalse':
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'quizType': QuizTypes.trueAndFalse,
            'numberOfPlayer': 1,
          },
        );
        return;
      case 'multiMatch':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.multiMatch,
          },
        );
        return;
    }
  }

  void onPressedTodayActivity(String title) {
    if (_isGuest) {
      _showLoginDialog();
      return;
    }

    switch (title) {
      case 'Quiz of the day':
        Navigator.pushNamed(
          context,
          Routes.category,
          arguments: {
            'quizType': QuizTypes.mathMania,
          },
        );
        return;

      case 'Featured Quiz':
        Navigator.pushNamed(
          context,
          Routes.category,
          arguments: {
            'quizType': QuizTypes.guessTheWord,
          },
        );
        return;

      case 'Fun Friday':
        Navigator.of(context).pushNamed(
          Routes.category,
          arguments: {
            'quizType': QuizTypes.funAndLearn,
            'numberOfPlayer': 1,
          },
        );
        return;
    }
  }
  // void _onPressedSelfExam(String index) {
  //   if (_isGuest) {
  //     _showLoginDialog();
  //     return;
  //   }
  //
  //   if (index == 'Quiz of the day') {
  //     context.read<ExamCubit>().updateState(ExamInitial());
  //     Navigator.of(context).pushNamed(Routes.funAndLearn);
  //   } else if (index == 'Featured Quiz') {
  //     context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
  //     context.read<SubCategoryCubit>().updateState(SubCategoryInitial());
  //     Navigator.of(context).pushNamed(Routes.funAndLearn);
  //   }
  //   else if (index == 'Fun Friday') {
  //     context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
  //     context.read<SubCategoryCubit>().updateState(SubCategoryInitial());
  //     Navigator.of(context).pushNamed(Routes.funAndLearn);
  //   }
  //
  // }
  // void _onPressedSelfExam(String index) {
  //   if (_isGuest) {
  //     _showLoginDialog();
  //     return;
  //   }
  //
  //   if (index == 'exam') {
  //     context.read<ExamCubit>().updateState(ExamInitial());
  //     Navigator.of(context).pushNamed(Routes.exams);
  //   } else if (index == 'selfChallenge') {
  //     context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
  //     context.read<SubCategoryCubit>().updateState(SubCategoryInitial());
  //     Navigator.of(context).pushNamed(Routes.selfChallenge);
  //   }
  // }

  void _onPressedBattle(String index) {
    if (_isGuest) {
      _showLoginDialog();
      return;
    }

    context.read<QuizCategoryCubit>().updateState(QuizCategoryInitial());
    if (index == 'groupPlay') {
      context
          .read<MultiUserBattleRoomCubit>()
          .updateState(MultiUserBattleRoomInitial());

      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (context) =>
                UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
            child: CreateOrJoinRoomScreen(
              quizType: QuizTypes.groupPlay,
              title: context.tr('groupPlay')!,
            ),
          ),
        ),
      );
    } else if (index == 'battleQuiz') {
      context.read<BattleRoomCubit>().updateState(
            BattleRoomInitial(),
            cancelSubscription: true,
          );

      if (_sysConfigCubit.isRandomBattleEnabled) {
        Navigator.of(context).pushNamed(Routes.randomBattle);
      } else {
        Navigator.of(context).push(
          CupertinoPageRoute<CreateOrJoinRoomScreen>(
            builder: (_) => BlocProvider<UpdateScoreAndCoinsCubit>(
              create: (_) =>
                  UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
              child: CreateOrJoinRoomScreen(
                quizType: QuizTypes.oneVsOneBattle,
                title: context.tr('playWithFrdLbl')!,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showLoginDialog() {
    return showLoginDialog(
      context,
      onTapYes: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(Routes.login);
      },
    );
  }

  late String _userName = context.tr('guest')!;
  late String _userProfileImg = Assets.profile('2.png');

  // Widget _buildProfileContainer() {
  //   return Align(
  //     alignment: Alignment.topCenter,
  //     child: GestureDetector(
  //       onTap: _onTapProfile,
  //       child: Container(
  //         margin: EdgeInsets.only(
  //           top: _statusBarPadding * .2,
  //           left: hzMargin,
  //           right: hzMargin,
  //         ),
  //         width: scrWidth,
  //         child: LayoutBuilder(
  //           builder: (_, constraint) {
  //             final size = context;
  //
  //             return Row(
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(3),
  //                   width: constraint.maxWidth * 0.15,
  //                   height: constraint.maxWidth * 0.15,
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     border: Border.all(
  //                       color: Theme.of(context)
  //                           .colorScheme
  //                           .onTertiary
  //                           .withValues(alpha: 0.3),
  //                     ),
  //                   ),
  //                   child: QImage.circular(imageUrl: _userProfileImg),
  //                 ),
  //                 SizedBox(width: size.width * .03),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       context.tr(welcome)!,
  //                       style: const TextStyle(
  //                         fontSize: 15,
  //                         color: Colors.black,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     SizedBox(
  //                       width: constraint.maxWidth * 0.5,
  //                       child: Text(
  //                         '${context.tr(helloKey)!} ${_isGuest ? context.tr('guest')! : _userName}',
  //                         maxLines: 1,
  //                         style: _boldTextStyle,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //
  //                 const Spacer(),
  //
  //                 /// LeaderBoard
  // Container(
  //   width: size.width * 0.11,
  //   height: size.width * 0.11,
  //   decoration: BoxDecoration(
  //     color: Theme.of(context).primaryColor,
  //     borderRadius: BorderRadius.circular(10),
  //   ),
  //   child: IconButton(
  //     onPressed: _onTapLeaderboard,
  //     icon: _isGuest
  //         ? const Icon(
  //             Icons.login_rounded,
  //             color: Colors.white,
  //           )
  //         : QImage(
  //             imageUrl: Assets.leaderboardIcon,
  //             color: Colors.white,
  //             width: size.width * 0.08,
  //             height: size.width * 0.08,
  //           ),
  //   ),
  // ),
  // Container(
  //   width: size.width * 0.11,
  //   height: size.width * 0.11,
  //   decoration: BoxDecoration(
  //     color: Theme.of(context).primaryColor,
  //     borderRadius: BorderRadius.circular(10),
  //   ),
  //   child: IconButton(
  //     onPressed: _onTapLeaderboard,
  //     icon: _isGuest
  //         ? const Icon(
  //             Icons.login_rounded,
  //             color: Colors.white,
  //           )
  //         : QImage(
  //             imageUrl: Assets.leaderboardIcon,
  //             color: Colors.white,
  //             width: size.width * 0.08,
  //             height: size.width * 0.08,
  //           ),
  //   ),
  // ),
  //
  //                 ///notification
  //
  //                 SizedBox(
  //                   width: size.width * 0.11,
  //                   height: size.width * 0.11,
  //                   child: IconButton(
  //                     onPressed: () {
  //                       Navigator.of(context).pushNamed(Routes.notification);
  //                     },
  //                     icon: QImage(
  //                       imageUrl: Assets.notificationAlarmIcon,
  //                       width: size.width * 0.08,
  //                       height: size.width * 0.08,
  //                     ),
  //                   ),
  //                 ),
  //                 // const SizedBox(width: 2),
  //                 const Spacer(),
  //
  //                 ///Coins
  //
  //                 Container(
  //                   width: size.width * 0.16,
  //                   height: size.height * 0.04,
  //                   padding: const EdgeInsets.symmetric(horizontal: 5),
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).primaryColor,
  //                     borderRadius: BorderRadius.circular(15),
  //                   ),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       QImage(
  //                         imageUrl: Assets.coins,
  //                         width: size.width * 0.04,
  //                         height: size.width * 0.03,
  //                       ),
  //                       const SizedBox(width: 6),
  //                       Text(
  //                         _userCoins,
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: size.width * 0.0373,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //
  //                 /// Settings
  //                 // Container(
  //                 //   width: size.width * 0.11,
  //                 //   height: size.width * 0.11,
  //                 //   decoration: BoxDecoration(
  //                 //     color: Theme.of(context).primaryColor,
  //                 //     borderRadius: BorderRadius.circular(10),
  //                 //   ),
  //                 //   child: IconButton(
  //                 //     onPressed: () {
  //                 //       Navigator.of(context).pushNamed(Routes.settings);
  //                 //     },
  //                 //     icon: QImage(
  //                 //       imageUrl: Assets.notificationAlarmIcon,
  //                 //       color: Colors.white,
  //                 //       width: size.width * 0.08,
  //                 //       height: size.width * 0.08,
  //                 //     ),
  //                 //   ),
  //                 // ),
  //               ],
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget buildDailyQuotes() {
    return const DailyQuoteScreen();
  }

  Widget _buildZones() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hzMargin),
          child: Wrap(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 30,
                        // horizontal: 5,
                      ),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black12,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/daily_quiz_banner.png',
                            width: 148,
                            height: 85,
                          ),
                          const SizedBox(width: 21),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                            [
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Daily Task',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    onPressed: () {
                                                      if (_isGuest) {
                                                        Navigator.pushNamed(
                                                          context,
                                                          Routes.login,
                                                        );
                                                      } else {
                                                        Navigator.of(context).pushNamed(
                                                          Routes.quiz,
                                                          arguments: {
                                                            'quizType': QuizTypes.trueAndFalse,
                                                            'numberOfPlayer': 1,
                                                          },
                                                        );
                                                      }
                                                    },
                                                    icon: const QImage(
                                                      imageUrl: Assets.playIcon,
                                                      width: 10,
                                                      height: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                '14 Questions',
                                                style: TextStyle(
                                                  color: Color(0xFF6C7278),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: LinearProgressIndicator(
                                    value: 9 / 14,
                                    backgroundColor: Colors.grey[300],
                                    color: const Color(0xFFCD2222),
                                    minHeight: 3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Text(
                                      'Progress',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6C7278),
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      '9/14',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6C7278),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // child: Container(
                    //   decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(10),
                    //     color: Theme.of(context).colorScheme.surface,
                    //   ),
                    //   margin: EdgeInsets.only(
                    //     left: hzMargin,
                    //     right: hzMargin,
                    //     top: 10,
                    //     bottom: 26,
                    //   ),
                    //   width: context.width,
                    //   child: quizZoneCategories(),
                    // ),
                  ),

                  /// Expand Arrow
                  // if (canExpandCategoryList) ...[
                  //   Positioned(
                  //     left: 0,
                  //     right: 0,
                  //     // Position the center bottom arrow, from here
                  //     bottom: -9,
                  //     child: Container(
                  //       width: 50,
                  //       height: 50,
                  //       decoration: BoxDecoration(
                  //         border: Border.all(color: Colors.transparent),
                  //         shape: BoxShape.circle,
                  //         color: Theme.of(context).scaffoldBackgroundColor,
                  //       ),
                  //       child: GestureDetector(
                  //         onTap: () => setState(() {
                  //           isCateListExpanded = !isCateListExpanded;
                  //         }),
                  //         child: Container(
                  //           width: 30,
                  //           height: 30,
                  //           margin: const EdgeInsets.all(4),
                  //           decoration: BoxDecoration(
                  //             color: Theme.of(context).colorScheme.surface,
                  //             shape: BoxShape.circle,
                  //           ),
                  //           child: Icon(
                  //             !isCateListExpanded
                  //                 ? Icons.keyboard_arrow_down_rounded
                  //                 : Icons.keyboard_arrow_up_rounded,
                  //             color: Theme.of(context).primaryColor,
                  //             size: 32,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ],
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   child: Column(
        //     // crossAxisAlignment: CrossAxisAlignment.center,
        //     children: [
        //       const Text(
        //         '“Success is not final, failure is not fatal, it is the courage to continue that counts.”',
        //         style: TextStyle(
        //           fontStyle: FontStyle.italic,
        //           color: Colors.black,
        //           fontSize: 14,
        //           fontWeight: FontWeight.bold,
        //         ),
        //         textAlign: TextAlign.center,
        //       ),
        //       const SizedBox(height: 12),
        //       const Text.rich(
        //         TextSpan(
        //           children: [
        //             TextSpan(
        //               text: 'Yesterday | Submitted by ',
        //               style: TextStyle(
        //                 fontSize: 12,
        //                 fontWeight: FontWeight.w400,
        //                 color: Colors.grey,
        //               ),
        //             ),
        //             TextSpan(
        //               text: 'Aarav',
        //               style: TextStyle(
        //                 fontSize: 12,
        //                 fontWeight: FontWeight.bold,
        //                 color: Colors.grey,
        //               ),
        //             ),
        //           ],
        //         ),
        //         textAlign: TextAlign.center,
        //       ),
        //       const SizedBox(height: 12),
        //       SizedBox(
        //         height: 36,
        //         child: ElevatedButton(
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Theme.of(context).primaryColor,
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(8),
        //             ),
        //             padding: const EdgeInsets.symmetric(horizontal: 12),
        //           ),
        //           onPressed: () {
        //             // TODO: Add submit logic here
        //           },
        //           child: const Row(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               Text(
        //                 'Submit Quote',
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   fontWeight: FontWeight.bold,
        //                   color: Colors.white,
        //                 ),
        //               ),
        //               SizedBox(width: 8),
        //               QImage(
        //                 imageUrl: Assets.penLineIcon,
        //                 width: 17,
        //                 height: 17,
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildExamSelf() {
    void onTapViewAll() {
      if (_sysConfigCubit.isContestEnabled) {
        Navigator.of(context).pushNamed(Routes.contest);
      } else {
        UiUtils.showSnackBar(
          context.tr(currentlyNotAvailableKey)!,
          context,
        );
      }
    }

    return todayActivityZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr(todayActivity) ?? todayActivity,
                      style: _boldTextStyle.copyWith(color: Colors.black),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (_isGuest) {
                          _showLoginDialog();
                        } else {
                          // Navigator.of(context).pushNamed(Routes.badges);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            context.tr(viewMoreKey) ?? viewMoreKey,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5486F2),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.4),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(
                    todayActivityZones.length,
                    (i) => ActivityCard(
                      onTap: () =>
                          onPressedTodayActivity(todayActivityZones[i].title),
                      title: context.tr(todayActivityZones[i].title)!,
                      desc: context.tr(todayActivityZones[i].desc)!,
                      // strokeColor: todayActivityZones[i].strokeColor,
                      // titleColor: todayActivityZones[i].titleColor,
                      // img: examZones[i].img,
                    ),
                    // (i) => QuizGridCard(
                    //   onTap: () => _onPressedSelfExam(examZones[i].title),
                    //   title: context.tr(examZones[i].title)!,
                    //   desc: context.tr(examZones[i].desc)!,
                    //   img: examZones[i].img,
                    // ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildLearnAndExplore() {
    return learnAndExploreZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('Learn & Explore') ?? 'Learn & Explore',
                      style: _boldTextStyle.copyWith(color: Colors.black),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (_isGuest) {
                          _showLoginDialog();
                        } else {
                          // Navigator.of(context).pushNamed(Routes.badges);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            context.tr(seeAllKey) ?? seeAllKey,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5486F2),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    learnAndExploreZones.length,
                    (i) => LearnAndExploreCard(
                      // onTap: () => _onPressedLearnExplore(todayActivityZones[i].title),
                      img: learnAndExploreZones[i].img,
                      title: context.tr(learnAndExploreZones[i].title)!,
                      desc: context.tr(learnAndExploreZones[i].desc)!,
                      // modules: context.tr(learnAndExploreZones[i].desc)!,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget _buildBattle() {
    return battleZones.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
              left: hzMargin,
              right: hzMargin,
              top: scrHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Zone Title: Battle
                // Text(
                //   context.tr(battleOfTheDayKey) ?? battleOfTheDayKey, //
                //   style: _boldTextStyle,
                // ),

                /// Categories
                Padding(
                  padding: EdgeInsets.only(
                    top: _statusBarPadding * 0.2,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 13,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 1-on-1 Battle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Battle’s Of The Day\n1-on-1 Battle Mode',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Spacer(),
                                  QImage(
                                    imageUrl: Assets.trophyIcon,
                                    width: 40,
                                    height: 40,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Challenge your peers & win extra coins!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6C7278), // Gray 600
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute<CreateOrJoinRoomScreen>(
                                      builder: (_) => BlocProvider<
                                          UpdateScoreAndCoinsCubit>(
                                        create: (_) => UpdateScoreAndCoinsCubit(
                                          ProfileManagementRepository(),
                                        ),
                                        child: CreateOrJoinRoomScreen(
                                          quizType: QuizTypes.oneVsOneBattle,
                                          title: context.tr('playWithFrdLbl')!,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Start a Challenge',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Group Battle Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Battle’s Of The Day\nGroup Battle Mode',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Spacer(),
                                  QImage(
                                    imageUrl: Assets.groupBattleIcon,
                                    color: Color(0xFFCD2222),
                                    width: 40,
                                    height: 40,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Join a group and battle together for big rewards!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6C7278), // Gray 600
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute<void>(
                                      builder: (_) => BlocProvider<
                                          UpdateScoreAndCoinsCubit>(
                                        create: (context) =>
                                            UpdateScoreAndCoinsCubit(
                                          ProfileManagementRepository(),
                                        ),
                                        child: CreateOrJoinRoomScreen(
                                          quizType: QuizTypes.groupPlay,
                                          title: context.tr('groupPlay')!,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Join Group Battle',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  Widget quizZoneCategories() {
    return BlocConsumer<QuizoneCategoryCubit, QuizoneCategoryState>(
      bloc: context.read<QuizoneCategoryCubit>(),
      listener: (context, state) {
        if (state is QuizoneCategoryFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is QuizoneCategoryFailure) {
          return ErrorContainer(
            showRTryButton: false,
            showBackButton: false,
            showErrorImage: false,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: () {
              context.read<QuizoneCategoryCubit>().getQuizCategoryWithUserId(
                    languageId: UiUtils.getCurrentQuizLanguageId(context),
                  );
            },
          );
        }

        if (state is QuizoneCategorySuccess) {
          final categories = state.categories;
          final int categoriesToShowCount;

          /// Min/Max Categories to Show.
          const minCount = 2;
          const maxCount = 5;

          /// need to check old cate list with new cate list, when we change languages.
          /// and rebuild the list.
          if (oldCategoriesToShowCount != categories.length) {
            Future.delayed(Duration.zero, () {
              oldCategoriesToShowCount = categories.length;
              canExpandCategoryList = oldCategoriesToShowCount > minCount;
              setState(() {});
            });
          }

          if (!isCateListExpanded) {
            categoriesToShowCount =
                categories.length <= minCount ? categories.length : minCount;
          } else {
            categoriesToShowCount =
                categories.length <= maxCount ? categories.length : maxCount;
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 10),
            shrinkWrap: true,
            itemCount: categoriesToShowCount,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              final category = categories[i];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () {
                  if (_isGuest) {
                    _showLoginDialog();
                    return;
                  }

                  if (category.isPremium &&
                      !category.hasUnlocked &&
                      !category.hasSubcategories &&
                      !category.hasLevels) {
                    showUnlockPremiumCategoryDialog(
                      context,
                      categoryId: category.id!,
                      categoryName: category.categoryName!,
                      requiredCoins: category.requiredCoins,
                      isQuizZone: true,
                    );
                    return;
                  }

                  //noOf means how many subcategory it has
                  //if subcategory is 0 then check for level
                  if (!category.hasSubcategories) {
                    //means this category does not have level
                    if (category.maxLevel == '0') {
                      //direct move to quiz screen pass level as 0
                      Navigator.of(context).pushNamed(
                        Routes.quiz,
                        arguments: {
                          'numberOfPlayer': 1,
                          'quizType': QuizTypes.quizZone,
                          'categoryId': category.id,
                          'subcategoryId': '',
                          'level': '0',
                          'subcategoryMaxLevel': '0',
                          'unlockedLevel': 0,
                          'contestId': '',
                          'comprehensionId': '',
                          'showRetryButton': category.hasQuestions,
                        },
                      );
                    } else {
                      Navigator.of(context).pushNamed(
                        Routes.levels,
                        arguments: {
                          'Category': category,
                          'quizType': QuizTypes.quizZone,
                        },
                      );
                    }
                  } else {
                    Navigator.of(context).pushNamed(
                      Routes.subcategoryAndLevel,
                      arguments: {
                        'category': category,
                        'quizType': QuizTypes.quizZone,
                      },
                    );
                  }
                },
                horizontalTitleGap: 15,
                leading: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: QImage(
                        imageUrl: category.image!,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                /// right_arrow
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumCategoryAccessBadge(
                      hasUnlocked: category.hasUnlocked,
                      isPremium: category.isPremium,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ],
                ),
                title: Text(
                  category.categoryName!,
                  style: _boldTextStyle.copyWith(fontSize: 16),
                ),
                subtitle: Text(
                  category.hasSubcategories
                      ? "${context.tr('subCategoriesLbl')}: ${category.subcategoriesCount}"
                      : "${context.tr("questionLbl")}: ${category.questionsCount}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onTertiary
                        .withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: CircularProgressContainer());
      },
    );
  }

  // Widget _buildBattle() {
  //   return battleZones.isNotEmpty
  //       ? Padding(
  //           padding: EdgeInsets.only(
  //             left: hzMargin,
  //             right: hzMargin,
  //             top: scrHeight * 0.03,
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               /// Zone Title: Battle
  //               Text(
  //                 context.tr(battleOfTheDayKey) ?? battleOfTheDayKey, //
  //                 style: _boldTextStyle,
  //               ),
  //
  //               /// Categories
  //               GridView.count(
  //                 // Create a grid with 2 columns. If you change the scrollDirection to
  //                 // horizontal, this produces 2 rows.
  //                 crossAxisCount: 2,
  //                 shrinkWrap: true,
  //                 mainAxisSpacing: 20,
  //                 padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
  //                 crossAxisSpacing: 20,
  //                 physics: const NeverScrollableScrollPhysics(),
  //                 // Generate 100 widgets that display their index in the List.
  //                 children: List.generate(
  //                   battleZones.length,
  //                   (i) => QuizGridCard(
  //                     onTap: () => _onPressedBattle(battleZones[i].title),
  //                     title: context.tr(battleZones[i].title)!,
  //                     desc: context.tr(battleZones[i].desc)!,
  //                     img: battleZones[i].img,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )
  //       : const SizedBox();
  // }

  // Widget _buildExamSelf() {
  //   return examZones.isNotEmpty
  //       ? Padding(
  //           padding: EdgeInsets.only(
  //             left: hzMargin,
  //             right: hzMargin,
  //             top: scrHeight * 0.04,
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 context.tr(selfExamZoneKey) ?? selfExamZoneKey,
  //                 style: _boldTextStyle,
  //               ),
  //               GridView.count(
  //                 crossAxisCount: 2,
  //                 shrinkWrap: true,
  //                 mainAxisSpacing: 20,
  //                 padding: EdgeInsets.only(top: _statusBarPadding * 0.2),
  //                 crossAxisSpacing: 20,
  //                 physics: const NeverScrollableScrollPhysics(),
  //                 // Generate 100 widgets that display their index in the List.
  //                 children: List.generate(
  //                   examZones.length,
  //                   (i) => QuizGridCard(
  //                     onTap: () => _onPressedSelfExam(examZones[i].title),
  //                     title: context.tr(examZones[i].title)!,
  //                     desc: context.tr(examZones[i].desc)!,
  //                     img: examZones[i].img,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )
  //       : const SizedBox();
  // }

  // Widget _buildZones() {
  //   return Padding(
  //     padding: EdgeInsets.only(
  //       left: hzMargin,
  //       right: hzMargin,
  //       top: scrHeight * 0.04,
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         if (playDifferentZones.isNotEmpty)
  //           Text(
  //             context.tr(playDifferentZoneKey) ?? playDifferentZoneKey,
  //             style: _boldTextStyle,
  //           )
  //         else
  //           const SizedBox(),
  //         GridView.count(
  //           crossAxisCount: 2,
  //           shrinkWrap: true,
  //           mainAxisSpacing: 20,
  //           padding: EdgeInsets.only(
  //             top: _statusBarPadding * 0.2,
  //             bottom: _statusBarPadding * 0.6,
  //           ),
  //           crossAxisSpacing: 20,
  //           physics: const NeverScrollableScrollPhysics(),
  //           children: List.generate(
  //             playDifferentZones.length,
  //             (i) => QuizGridCard(
  //               onTap: () => _onPressedZone(playDifferentZones[i].title),
  //               title: context.tr(playDifferentZones[i].title)!,
  //               desc: context.tr(playDifferentZones[i].desc)!,
  //               img: playDifferentZones[i].img,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDailyAds() {
  //   var clicked = false;
  //   return BlocBuilder<RewardedAdCubit, RewardedAdState>(
  //     builder: (context, state) {
  //       if (state is RewardedAdLoaded &&
  //           context.read<UserDetailsCubit>().isDailyAdAvailable) {
  //         return GestureDetector(
  //           onTap: () async {
  //             if (!clicked) {
  //               await context
  //                   .read<RewardedAdCubit>()
  //                   .showDailyAd(context: context);
  //               clicked = true;
  //             }
  //           },
  //           child: Container(
  //             margin: EdgeInsets.only(
  //               left: hzMargin,
  //               right: hzMargin,
  //               top: scrHeight * 0.02,
  //             ),
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(8),
  //               color: Theme.of(context).colorScheme.surface,
  //             ),
  //             width: scrWidth,
  //             height: scrWidth * 0.3,
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 DecoratedBox(
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).primaryColor,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: SvgPicture.asset(
  //                     Assets.dailyCoins,
  //                     width: scrWidth * .23,
  //                     height: scrWidth * .23,
  //                   ),
  //                 ),
  //                 Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     ConstrainedBox(
  //                       constraints: const BoxConstraints(maxWidth: 250),
  //                       child: Text(
  //                         context.tr('dailyAdsTitle')!,
  //                         maxLines: 2,
  //                         style: TextStyle(
  //                           fontWeight: FontWeights.bold,
  //                           fontSize: 16,
  //                           color: Theme.of(context).colorScheme.onTertiary,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 5),
  //                     Text(
  //                       "${context.tr("get")!} "
  //                       '${_sysConfigCubit.coinsPerDailyAdView} '
  //                       "${context.tr("dailyAdsDesc")!}",
  //                       style: TextStyle(
  //                         fontWeight: FontWeights.regular,
  //                         fontSize: 14,
  //                         color: Theme.of(context)
  //                             .colorScheme
  //                             .onTertiary
  //                             .withValues(alpha: .6),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       }
  //
  //       return const SizedBox.shrink();
  //     },
  //   );
  // }

  // Widget _buildLiveContestSection() {
  //   void onTapViewAll() {
  //     if (_sysConfigCubit.isContestEnabled) {
  //       Navigator.of(context).pushNamed(Routes.contest);
  //     } else {
  //       UiUtils.showSnackBar(
  //         context.tr(currentlyNotAvailableKey)!,
  //         context,
  //       );
  //     }
  //   }
  //
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: hzMargin, vertical: 10),
  //     child: Column(
  //       children: [
  //         /// Contest Section Title
  //         Row(
  //           children: [
  //             Text(
  //               context.tr(contest) ?? contest,
  //               style: _boldTextStyle,
  //             ),
  //             const Spacer(),
  //             GestureDetector(
  //               onTap: onTapViewAll,
  //               child: Text(
  //                 context.tr(viewAllKey) ?? viewAllKey,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                   color: Theme.of(context)
  //                       .colorScheme
  //                       .onTertiary
  //                       .withValues(alpha: 0.6),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //
  //         /// Contest Card
  //         BlocConsumer<ContestCubit, ContestState>(
  //           bloc: context.read<ContestCubit>(),
  //           listener: (context, state) {
  //             if (state is ContestFailure) {
  //               if (state.errorMessage == errorCodeUnauthorizedAccess) {
  //                 showAlreadyLoggedInDialog(context);
  //               }
  //             }
  //           },
  //           builder: (context, state) {
  //             if (state is ContestFailure) {
  //               return Container(
  //                 decoration: BoxDecoration(
  //                   color: Theme.of(context).colorScheme.surface,
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 height: 100,
  //                 alignment: Alignment.center,
  //                 child: Text(
  //                   context.tr(
  //                     convertErrorCodeToLanguageKey(state.errorMessage),
  //                   )!,
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeights.regular,
  //                     color: Theme.of(context).primaryColor,
  //                   ),
  //                   maxLines: 2,
  //                 ),
  //               );
  //             }
  //
  //             if (state is ContestSuccess) {
  //               final colorScheme = Theme.of(context).colorScheme;
  //               final textStyle = GoogleFonts.nunito(
  //                 textStyle: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeights.regular,
  //                   color: colorScheme.onTertiary.withValues(alpha: 0.6),
  //                 ),
  //               );
  //
  //               ///
  //               final live = state.contestList.live;
  //
  //               /// No Contest
  //               if (live.errorMessage.isNotEmpty) {
  //                 return Container(
  //                   decoration: BoxDecoration(
  //                     color: colorScheme.surface,
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   height: 100,
  //                   alignment: Alignment.center,
  //                   child: Text(
  //                     context.tr(
  //                       convertErrorCodeToLanguageKey(live.errorMessage),
  //                     )!,
  //                     style: _boldTextStyle.copyWith(
  //                       fontSize: 16,
  //                       color: Theme.of(context).primaryColor,
  //                     ),
  //                   ),
  //                 );
  //               }
  //
  //               final contest = live.contestDetails.first;
  //               final entryFee = int.parse(contest.entry!);
  //
  //               void onTapPlayNow() {
  //                 final userDetailsCubit = context.read<UserDetailsCubit>();
  //
  //                 if (int.parse(userDetailsCubit.getCoins()!) >= entryFee) {
  //                   context.read<UpdateScoreAndCoinsCubit>().updateCoins(
  //                         coins: entryFee,
  //                         addCoin: false,
  //                         title: playedContestKey,
  //                       );
  //                   userDetailsCubit.updateCoins(
  //                     addCoin: false,
  //                     coins: entryFee,
  //                   );
  //
  //                   Navigator.of(context).pushNamed(
  //                     Routes.quiz,
  //                     arguments: {
  //                       'numberOfPlayer': 1,
  //                       'quizType': QuizTypes.contest,
  //                       'contestId': contest.id,
  //                     },
  //                   );
  //                 } else {
  //                   showNotEnoughCoinsDialog(context);
  //                 }
  //               }
  //
  //               return Container(
  //                 decoration: const BoxDecoration(
  //                   color: Colors.transparent,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       offset: Offset(0, 5),
  //                       blurRadius: 5,
  //                       color: Colors.black12,
  //                     ),
  //                   ],
  //                   borderRadius: BorderRadius.vertical(
  //                     bottom: Radius.circular(99999),
  //                   ),
  //                 ),
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: colorScheme.surface,
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   padding: const EdgeInsets.all(12.5),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           /// Contest Image
  //                           Container(
  //                             padding: const EdgeInsets.all(5),
  //                             decoration: BoxDecoration(
  //                               color: Colors.transparent,
  //                               borderRadius: BorderRadius.circular(10),
  //                               border: Border.all(
  //                                 color:
  //                                     Theme.of(context).scaffoldBackgroundColor,
  //                               ),
  //                             ),
  //                             child: ClipRRect(
  //                               borderRadius: BorderRadius.circular(5),
  //                               child: QImage(
  //                                 imageUrl: contest.image!,
  //                                 height: 45,
  //                                 width: 45,
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //
  //                           /// Contest Name & Description
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(
  //                                   contest.name.toString(),
  //                                   textAlign: TextAlign.left,
  //                                   overflow: TextOverflow.ellipsis,
  //                                   maxLines: 2,
  //                                   style: _boldTextStyle.copyWith(
  //                                     fontSize: 16,
  //                                   ),
  //                                 ),
  //                                 Text(
  //                                   contest.description.toString(),
  //                                   softWrap: true,
  //                                   textAlign: TextAlign.left,
  //                                   overflow: TextOverflow.ellipsis,
  //                                   maxLines: 2,
  //                                   style: textStyle,
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 10),
  //
  //                       ///
  //                       Column(
  //                         // runSpacing: 10,
  //                         // spacing: 15,
  //                         // crossAxisAlignment: WrapCrossAlignment.center,
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               /// Entry Fees
  //                               Text.rich(
  //                                 TextSpan(
  //                                   children: [
  //                                     TextSpan(
  //                                       text: context.tr('entryFeesLbl'),
  //                                     ),
  //                                     const TextSpan(text: ' : '),
  //                                     TextSpan(
  //                                       text:
  //                                           "$entryFee ${context.tr("coinsLbl")!}",
  //                                       style: textStyle.copyWith(
  //                                         color: colorScheme.onTertiary,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                                 style: textStyle,
  //                               ),
  //                               const SizedBox(height: 5),
  //
  //                               /// Ends on
  //                               Text.rich(
  //                                 style: textStyle,
  //                                 TextSpan(
  //                                   children: [
  //                                     TextSpan(
  //                                       text: context.tr('endsOnLbl'),
  //                                     ),
  //                                     const TextSpan(text: ' : '),
  //                                     TextSpan(
  //                                       text: '${contest.endDate}  |  ',
  //                                       style: textStyle.copyWith(
  //                                         color: colorScheme.onTertiary,
  //                                       ),
  //                                     ),
  //                                     TextSpan(
  //                                       text: contest.participants.toString(),
  //                                       style: textStyle.copyWith(
  //                                         color: colorScheme.onTertiary,
  //                                       ),
  //                                     ),
  //                                     const TextSpan(text: ' : '),
  //                                     TextSpan(
  //                                       text: context.tr(
  //                                         'playersLbl',
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //
  //                           const SizedBox(height: 15),
  //
  //                           /// Play Now
  //                           GestureDetector(
  //                             onTap: onTapPlayNow,
  //                             child: Container(
  //                               width: double.maxFinite,
  //                               padding: const EdgeInsets.symmetric(
  //                                 vertical: 8,
  //                                 horizontal: 5,
  //                               ),
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(8),
  //                                 color:
  //                                     Theme.of(context).scaffoldBackgroundColor,
  //                               ),
  //                               child: Text(
  //                                 context.tr('playnowLbl')!,
  //                                 maxLines: 1,
  //                                 textAlign: TextAlign.center,
  //                                 style: TextStyle(
  //                                   fontSize: 16,
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Theme.of(context).primaryColor,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             }
  //
  //             return const Center(child: CircularProgressContainer());
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _userRank = '0';
  String _userCoins = '0';
  String _userScore = '0';

  Widget _buildHome() {
    return BlocConsumer<AppLocalizationCubit, AppLocalizationState>(
      listener: (context, state) async {
        if (_isGuest) return;

        final currentLanguage = state.language.name;
        final userProfile = context.read<UserDetailsCubit>().getUserProfile();

        if (currentLanguage != userProfile.appLanguage) {
          await context
              .read<UserDetailsCubit>()
              .updateLanguage(currentLanguage);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            RefreshIndicator(
              color: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              onRefresh: () async {
                fetchUserDetails();

                _currLangId = UiUtils.getCurrentQuizLanguageId(context);
                final quizCubit = context.read<QuizCategoryCubit>();
                final quizZoneCubit = context.read<QuizoneCategoryCubit>();

                if (_isGuest) {
                  await quizCubit.getQuizCategory(
                    languageId: _currLangId,
                    type: _quizZoneId,
                  );
                  await quizZoneCubit.getQuizCategory(languageId: _currLangId);
                } else {
                  await quizCubit.getQuizCategoryWithUserId(
                    languageId: _currLangId,
                    type: _quizZoneId,
                  );

                  await quizZoneCubit.getQuizCategoryWithUserId(
                    languageId: _currLangId,
                  );
                  await context
                      .read<ContestCubit>()
                      .getContest(languageId: _currLangId);
                }
                setState(() {});
              },
              child: ListView(
                children: [
                  // _buildProfileContainer(),
                  // UserAchievements(
                  //   userRank: _userRank,
                  //   userCoins: _userCoins,
                  //   userScore: _userScore,
                  // ),
                  const SizedBox(height: 1),

                  // Conditional Sparkle Animation or Sad Sparkle
                  // AnimatedSwitcher(
                  //   duration: const Duration(milliseconds: 200),
                  //   switchInCurve: Curves.easeIn,
                  //   switchOutCurve: Curves.easeOut,
                  //   child: hasCoins
                  //       ? Lottie.asset(
                  //     'assets/animations/confetti.json',
                  //     key: const ValueKey('sparkle'),
                  //     width: 100,
                  //     height: 100,
                  //     repeat: true,
                  //   )
                  //       : Lottie.asset(
                  //     'assets/animations/confetti.json',
                  //     key: const ValueKey('sad'),
                  //     width: 50,
                  //     height: 50,
                  //     repeat: true,
                  //   ),
                  // ),
                  BlocBuilder<QuizoneCategoryCubit, QuizoneCategoryState>(
                    builder: (context, state) {
                      if (state is QuizoneCategoryFailure &&
                          state.errorMessage == errorCodeDataNotFound) {
                        return const SizedBox.shrink();
                      }

                      if (_sysConfigCubit.isQuizZoneEnabled) {
                        // return _buildCategory();
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  if (_sysConfigCubit.isAdsEnable &&
                      _sysConfigCubit.isDailyAdsEnabled &&
                      !_isGuest) ...[
                    // _buildDailyAds(),
                  ],
                  if (_sysConfigCubit.isContestEnabled && !_isGuest) ...[
                    // _buildLiveContestSection(),
                  ],
                  _buildZones(),
                  buildDailyQuotes(),
                  _buildExamSelf(),
                  _buildLearnAndExplore(),
                  _buildBattle(),
                ],
              ),
            ),
            if (showUpdateContainer) const UpdateAppContainer(),
          ],
        );
      },
    );
  }

  void fetchUserDetails() {
    context.read<UserDetailsCubit>().fetchUserDetails();
  }

  bool profileComplete = false;

  bool get hasCoins => 0 < int.parse(_userCoins);

  @override
  Widget build(BuildContext context) {
    /// need to add this here, cause textStyle doesn't update automatically when changing theme.
    _boldTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: Theme.of(context).colorScheme.onTertiary,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.only(
                top: _statusBarPadding * .2,
                left: hzMargin,
                right: hzMargin,
              ),
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraint) {
                  final size = MediaQuery.of(context).size;

                  return BlocBuilder<UserDetailsCubit, UserDetailsState>(
                    buildWhen: (previous, current) =>
                    current is UserDetailsFetchSuccess ||
                        current is UserDetailsFetchFailure,
                    builder: (context, state) {
                      // Defaults for guest or fallback
                      var profileImg = _userProfileImg;
                      var userName = _userName;
                      var userCoins = _userCoins;
                      var isGuest = _isGuest;

                      if (state is UserDetailsFetchSuccess) {
                        final user = state.userProfile;
                        profileImg = user.profileUrl ?? '';
                        userName = user.name ?? '';
                        userCoins = user.coins ?? '0';
                        isGuest = false;
                      }

                      return Row(
                        children: [
                          GestureDetector(
                            onTap: _onTapProfile,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              width: constraint.maxWidth * 0.15,
                              height: constraint.maxWidth * 0.15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiary
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: QImage.circular(imageUrl: profileImg),
                            ),
                          ),
                          SizedBox(width: size.width * .03),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr(welcome)!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                width: constraint.maxWidth * 0.5,
                                child: Text(
                                  '${context.tr(helloKey)!} ${isGuest ? context.tr('guest')! : userName.split(' ').first}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _boldTextStyle.copyWith(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Notification Button
                          SizedBox(
                            width: size.width * 0.11,
                            height: size.width * 0.11,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(Routes.notification);
                              },
                              icon: QImage(
                                imageUrl: Assets.notificationAlarmIcon,
                                width: size.width * 0.08,
                                height: size.width * 0.08,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Coins
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                QImage(
                                  imageUrl: Assets.coins,
                                  width: size.width * 0.04,
                                  height: size.width * 0.03,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  userCoins,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: size.width * 0.037,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          )
      ),
      body: SafeArea(
        child: _isGuest
            ? _buildHome()
            : BlocConsumer<UserDetailsCubit, UserDetailsState>(
                bloc: context.read<UserDetailsCubit>(),
                listener: (context, state) {
                  if (state is UserDetailsFetchSuccess) {
                    final currLang = context
                        .read<AppLocalizationCubit>()
                        .state
                        .language
                        .name;

                    if (state.userProfile.appLanguage != currLang) {
                      context.read<UserDetailsCubit>().updateLanguage(currLang);
                    }

                    UiUtils.fetchBookmarkAndBadges(
                      context: context,
                      userId: state.userProfile.userId!,
                    );
                    if (state.userProfile.profileUrl!.isEmpty ||
                        state.userProfile.name!.isEmpty) {
                      if (!profileComplete) {
                        profileComplete = true;

                        context.pushNamed(
                          Routes.selectProfile,
                          arguments: const CreateOrEditProfileScreenArgs(
                            isNewUser: false,
                          ),
                        );
                      }
                      return;
                    }
                  } else if (state is UserDetailsFetchFailure) {
                    if (state.errorMessage == errorCodeUnauthorizedAccess) {
                      showAlreadyLoggedInDialog(context);
                    }
                  }
                },
                builder: (context, state) {
                  if (state is UserDetailsFetchInProgress ||
                      state is UserDetailsInitial) {
                    return const Center(child: CircularProgressContainer());
                  }
                  if (state is UserDetailsFetchFailure) {
                    return Center(
                      child: ErrorContainer(
                        showBackButton: true,
                        errorMessage:
                            convertErrorCodeToLanguageKey(state.errorMessage),
                        onTapRetry: fetchUserDetails,
                        showErrorImage: true,
                      ),
                    );
                  }

                  final user = (state as UserDetailsFetchSuccess).userProfile;

                  _userName = user.name!;
                  _userProfileImg = user.profileUrl!;
                  _userRank = user.allTimeRank!;
                  _userCoins = user.coins!;
                  _userScore = user.allTimeScore!;

                  return _buildHome();
                },
              ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   // currentIndex: _selectedIndex,
      //   // onTap: _onItemTapped,
      //   selectedItemColor: Theme.of(context).primaryColor,
      //   unselectedItemColor: Colors.grey,
      //   backgroundColor: Colors.white,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.menu_book),
      //       label: 'Learn',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.workspace_premium),
      //       label: 'Certificates',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.card_giftcard),
      //       label: 'Rewards',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
    );
  }
}
