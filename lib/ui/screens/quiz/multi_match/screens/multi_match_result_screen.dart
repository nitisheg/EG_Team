import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/blocs/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/update_score_and_coins_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/profile_management/profile_management_repository.dart';
import 'package:flutterquiz/features/quiz/cubits/subcategory_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/unlocked_level_cubit.dart';
import 'package:flutterquiz/features/quiz/cubits/update_level_cubit.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/features/quiz/multi_match/models/multi_match_answer_type_enum.dart';
import 'package:flutterquiz/features/quiz/multi_match/models/multi_match_question_model.dart';
import 'package:flutterquiz/features/quiz/quiz_repository.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/ui/screens/quiz/multi_match/screens/multi_match_quiz_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/multi_match/screens/multi_match_review_screen.dart';
import 'package:flutterquiz/ui/screens/quiz/widgets/radial_result_container.dart';
import 'package:flutterquiz/ui/widgets/all.dart';
import 'package:flutterquiz/utils/answer_encryption.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

final class MultiMatchResultScreenArgs {
  MultiMatchResultScreenArgs({
    required this.questions,
    required this.quizScore,
    required this.totalLevels,
    required this.unlockedLevel,
    required this.categoryId,
    required this.timeTakenToCompleteQuiz,
    required this.isPremiumCategory,
    this.subcategoryId,
  });

  final List<MultiMatchQuestion> questions;
  final int quizScore;
  final int totalLevels;
  final int unlockedLevel;
  final String categoryId;
  final String? subcategoryId;
  final int timeTakenToCompleteQuiz;
  final bool isPremiumCategory;
}

class MultiMatchResultScreen extends StatefulWidget {
  const MultiMatchResultScreen({
    required this.args,
    super.key,
  });

  final MultiMatchResultScreenArgs args;

  @override
  State<MultiMatchResultScreen> createState() => _MultiMatchResultScreenState();

  static Route<dynamic> route(RouteSettings settings) {
    final args = settings.arguments! as MultiMatchResultScreenArgs;

    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<UpdateLevelCubit>(
            create: (_) => UpdateLevelCubit(QuizRepository()),
          ),
          //to update user score and coins
          BlocProvider<UpdateScoreAndCoinsCubit>(
            create: (_) =>
                UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
          ),
        ],
        child: MultiMatchResultScreen(args: args),
      ),
    );
  }
}

class _MultiMatchResultScreenState extends State<MultiMatchResultScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  late int _earnedCoins = UiUtils.coinsBasedOnWinPercentage(
    guessTheWordMaxWinningCoins:
        context.read<SystemConfigCubit>().guessTheWordMaxWinningCoins,
    percentage: _quizPercentage,
    quizType: QuizTypes.multiMatch,
    maxCoinsWinningPercentage:
        context.read<SystemConfigCubit>().maxCoinsWinningPercentage,
    maxWinningCoins: context.read<SystemConfigCubit>().maxWinningCoins,
  );
  late int _earnedScore = widget.args.quizScore;
  late final userName = context.read<UserDetailsCubit>().getUserName();

  late final _totalQuestions = widget.args.questions.length;
  late final _totalCorrectAnswers = _totalCorrectlyAnsweredQuestions();

  late final _quizPercentage = (_totalCorrectAnswers * 100) / _totalQuestions;

  late final _isWinner = _quizPercentage >=
      context.read<SystemConfigCubit>().quizWinningPercentage;

  late final _currLevel = int.parse(widget.args.questions.first.level);

  late final _showCoinsAndScore =
      _isWinner && _currLevel == widget.args.unlockedLevel;

  @override
  void initState() {
    super.initState();

    /// show ad
    Future.delayed(Duration.zero, () {
      if (!widget.args.isPremiumCategory) {
        context.read<InterstitialAdCubit>().showAd(context);
      }
    });

    Future.delayed(
      Duration.zero,
      () async {
        await _earnCoinsBasedOnWinPercentage();

        /// Double coins and score if playing Premium Category
        if (widget.args.isPremiumCategory) {
          setState(() {
            _earnedCoins = _earnedCoins * 2;
            _earnedScore = _earnedScore * 2;
          });
          log('Doubled the Earning : Earned Coins $_earnedCoins, Earned Score $_earnedScore');
        }

        _updateDetails();
        await _fetchUserDetails();
      },
    );
  }

  Future<void> _fetchUserDetails() async {
    await context.read<UserDetailsCubit>().fetchUserDetails();
  }

  int _totalCorrectlyAnsweredQuestions() {
    var correct = 0;
    for (final que in widget.args.questions) {
      final correctAnswers = AnswerEncryption.decryptCorrectAnswers(
        rawKey: context.read<UserDetailsCubit>().getUserFirebaseId(),
        correctAnswer: que.correctAnswer,
      );

      final bool isCorrectlyAnswered;
      if (que.answerType == MultiMatchAnswerType.multiSelect) {
        isCorrectlyAnswered =
            correctAnswers.length == que.submittedIds.length &&
                correctAnswers.toSet().containsAll(que.submittedIds.toSet());
      } else {
        isCorrectlyAnswered =
            listEquals<String>(correctAnswers, que.submittedIds);
      }

      if (isCorrectlyAnswered) {
        ++correct;
      }
    }
    return correct;
  }

  Future<void> _earnCoinsBasedOnWinPercentage() async {
    if (_isWinner) {
      final c = context.read<SystemConfigCubit>();

      _earnedCoins = UiUtils.coinsBasedOnWinPercentage(
        guessTheWordMaxWinningCoins: c.guessTheWordMaxWinningCoins,
        percentage: _quizPercentage,
        quizType: QuizTypes.multiMatch,
        maxCoinsWinningPercentage: c.maxCoinsWinningPercentage,
        maxWinningCoins: c.maxWinningCoins,
      );
    }
  }

  void _updateDetails() {
    /// like, coins, score, level, etc.
    if (_isWinner) {
      /// update unlocked level
      if (_currLevel == widget.args.unlockedLevel) {
        final updatedLevel = widget.args.unlockedLevel + 1;

        context.read<UpdateLevelCubit>().updateLevel(
              QuizTypes.multiMatch,
              widget.args.categoryId,
              widget.args.subcategoryId ?? '',
              updatedLevel.toString(),
            );

        // Update score and coins for user
        context.read<UpdateScoreAndCoinsCubit>().updateCoinsAndScore(
              _earnedScore,
              _earnedCoins,
              wonMultiMatchKey,
            );

        // Update locally
        context
            .read<UserDetailsCubit>()
            .updateCoins(addCoin: true, coins: _earnedCoins);
        context.read<UserDetailsCubit>().updateScore(_earnedScore);
      }

      if (widget.args.subcategoryId != null) {
        context.read<UnlockedLevelCubit>().fetchUnlockLevel(
              widget.args.categoryId,
              '',
              quizType: QuizTypes.multiMatch,
            );
      } else {
        context
            .read<SubCategoryCubit>()
            .fetchSubCategory(widget.args.categoryId);
      }
    }
  }

  void _onBack() {
    if (widget.args.subcategoryId == null) {
      context.read<UnlockedLevelCubit>().fetchUnlockLevel(
            widget.args.categoryId,
            '',
            quizType: QuizTypes.multiMatch,
          );
    } else {
      context.read<SubCategoryCubit>().fetchSubCategory(widget.args.categoryId);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        appBar: QAppBar(
          roundedAppBar: false,
          title: Text(context.tr('multiMatchQuizResultLbl')!),
          onTapBackButton: _onBack,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(child: _buildResultContainer(context)),
              const SizedBox(height: 20),
              _buildResultButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingMessage() {
    final String title;
    final String message;

    if (_quizPercentage <= 30) {
      title = goodEffort;
      message = keepLearning;
    } else if (_quizPercentage <= 50) {
      title = wellDone;
      message = makingProgress;
    } else if (_quizPercentage <= 70) {
      title = greatJob;
      message = closerToMastery;
    } else if (_quizPercentage <= 90) {
      title = excellentWork;
      message = keepGoing;
    } else {
      title = fantasticJob;
      message = achievedMastery;
    }

    final titleStyle = TextStyle(
      fontSize: 26,
      color: Theme.of(context).colorScheme.onTertiary,
      fontWeight: FontWeights.bold,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(title)!,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              Flexible(
                child: Text(
                  " ${userName.split(' ').first}",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    color: Theme.of(context).primaryColor,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeights.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          alignment: Alignment.center,
          width: context.shortestSide * .85,
          child: Text(
            context.tr(message)!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultContainer(BuildContext context) {
    final lottieAnimation = _isWinner
        ? 'assets/animations/confetti.json'
        : 'assets/animations/defeats.json';

    final userProfileUrl =
        context.read<UserDetailsCubit>().getUserProfile().profileUrl ?? '';

    return Screenshot(
      controller: screenshotController,
      child: Container(
        height: context.height * 0.560,
        width: context.width * 0.90,
        decoration: BoxDecoration(
          color: _isWinner
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.onTertiary.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            /// Confetti
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset(lottieAnimation, fit: BoxFit.fill),
            ),

            /// Greeting and User Profile Image
            Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var verticalSpacePercentage = 0.0;

                  if (constraints.maxHeight <
                      UiUtils.profileHeightBreakPointResultScreen) {
                    verticalSpacePercentage = 0.015;
                  } else {
                    verticalSpacePercentage = 0.035;
                  }

                  return Column(
                    children: [
                      _buildGreetingMessage(),
                      SizedBox(
                        height: constraints.maxHeight * verticalSpacePercentage,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          QImage.circular(
                            imageUrl: userProfileUrl,
                            width: 107,
                            height: 107,
                          ),
                          SvgPicture.asset(
                            Assets.hexagonFrame,
                            width: 132,
                            height: 132,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            /// Incorrect Answer
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: _buildResultDataWithIconContainer(
                '${_totalQuestions - _totalCorrectAnswers}/$_totalQuestions',
                Assets.wrong,
                EdgeInsetsDirectional.only(
                  start: 15,
                  bottom: _showCoinsAndScore ? 20.0 : 30.0,
                ),
              ),
            ),

            /// Correct Answer
            Align(
              alignment: _showCoinsAndScore
                  ? AlignmentDirectional.bottomStart
                  : AlignmentDirectional.bottomEnd,
              child: _buildResultDataWithIconContainer(
                '$_totalCorrectAnswers/$_totalQuestions',
                Assets.correct,
                _showCoinsAndScore
                    ? const EdgeInsetsDirectional.only(start: 15, bottom: 60)
                    : const EdgeInsetsDirectional.only(end: 15, bottom: 30),
              ),
            ),

            /// Earned Score
            if (_showCoinsAndScore)
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: _buildResultDataWithIconContainer(
                  _earnedScore.toString(),
                  Assets.score,
                  const EdgeInsetsDirectional.only(end: 15, bottom: 60),
                ),
              ),

            /// Earned Coins
            if (_showCoinsAndScore)
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: _buildResultDataWithIconContainer(
                  _earnedCoins.toString(),
                  Assets.earnedCoin,
                  const EdgeInsetsDirectional.only(end: 15, bottom: 20),
                ),
              ),

            /// Quiz Percentage
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var radialSizePercentage = 0.0;
                  if (constraints.maxHeight <
                      UiUtils.profileHeightBreakPointResultScreen) {
                    radialSizePercentage = 0.4;
                  } else {
                    radialSizePercentage = 0.325;
                  }

                  return Transform.translate(
                    offset: const Offset(0, 15),
                    child: RadialPercentageResultContainer(
                      percentage: _quizPercentage,
                      timeTakenToCompleteQuizInSeconds:
                          widget.args.timeTakenToCompleteQuiz,
                      size: Size(
                        constraints.maxHeight * radialSizePercentage,
                        constraints.maxHeight * radialSizePercentage,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDataWithIconContainer(
    String title,
    String icon,
    EdgeInsetsGeometry margin,
  ) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      width: context.width * 0.2125,
      height: 33,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onTertiary,
              BlendMode.srcIn,
            ),
            width: 19,
            height: 19,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiary,
              fontWeight: FontWeights.bold,
              fontSize: 18,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String buttonTitle,
    Function onTap,
    BuildContext context,
  ) {
    return CustomRoundedButton(
      widthPercentage: 0.90,
      backgroundColor: Theme.of(context).primaryColor,
      buttonTitle: buttonTitle,
      radius: 8,
      elevation: 5,
      showBorder: false,
      fontWeight: FontWeights.regular,
      height: 50,
      titleColor: Theme.of(context).colorScheme.surface,
      onTap: onTap as VoidCallback,
      textSize: 20,
    );
  }

  Widget _buildResultButtons(BuildContext context) {
    const buttonSpace = SizedBox(height: 15);

    return Column(
      children: [
        if (_isWinner && _currLevel != widget.args.totalLevels) ...[
          _buildPlayNextLevelButton(),
          buttonSpace,
        ],
        if (!_isWinner) ...[
          _buildPlayAgainButton(),
          buttonSpace,
        ],
        _buildReviewAnswersButton(),
        buttonSpace,
        _buildShareYourScoreButton(),
        buttonSpace,
        _buildHomeButton(),
        buttonSpace,
      ],
    );
  }

  Widget _buildPlayAgainButton() {
    return _buildButton(
      context.tr('playAgainBtn')!,
      () {
        Navigator.of(context).pushReplacementNamed(
          Routes.multiMatchQuiz,
          arguments: MultiMatchQuizArgs(
            categoryId: widget.args.categoryId,
            subcategoryId: widget.args.subcategoryId,
            level: _currLevel.toString(),
            unlockedLevel: widget.args.unlockedLevel,
            totalLevels: widget.args.totalLevels,
            isPremiumCategory: widget.args.isPremiumCategory,
          ),
        );
      },
      context,
    );
  }

  Widget _buildPlayNextLevelButton() {
    return _buildButton(
      context.tr('nextLevelBtn')!,
      () {
        final unlockedLevel = _currLevel == widget.args.unlockedLevel
            ? _currLevel + 1
            : widget.args.unlockedLevel;

        Navigator.of(context).pushReplacementNamed(
          Routes.multiMatchQuiz,
          arguments: MultiMatchQuizArgs(
            categoryId: widget.args.categoryId,
            subcategoryId: widget.args.subcategoryId,
            level: (_currLevel + 1).toString(),
            unlockedLevel: unlockedLevel,
            totalLevels: widget.args.totalLevels,
            isPremiumCategory: widget.args.isPremiumCategory,
          ),
        );
      },
      context,
    );
  }

  bool _unlockedReviewAnswersOnce = false;
  Widget _buildReviewAnswersButton() {
    void onTapYesReviewAnswers() {
      final reviewAnswersDeductCoins =
          context.read<SystemConfigCubit>().reviewAnswersDeductCoins;
      //check if user has enough coins
      if (int.parse(context.read<UserDetailsCubit>().getCoins()!) <
          reviewAnswersDeductCoins) {
        showNotEnoughCoinsDialog(context);
        return;
      }

      /// update coins
      context
          .read<UpdateScoreAndCoinsCubit>()
          .updateCoins(
            coins: reviewAnswersDeductCoins,
            addCoin: false,
            title: reviewAnswerLbl,
          )
          .then((_) {
        final state = context.read<UpdateScoreAndCoinsCubit>().state;
        if (state is UpdateScoreAndCoinsFailure) {
          context.shouldPop();
          UiUtils.showSnackBar(
            context.tr(convertErrorCodeToLanguageKey(state.errorMessage)) ??
                context.tr(errorCodeDefaultMessage)!,
            context,
          );
          return;
        } else if (state is UpdateScoreAndCoinsSuccess) {
          context.read<UserDetailsCubit>().updateCoins(
                addCoin: false,
                coins: reviewAnswersDeductCoins,
              );

          _unlockedReviewAnswersOnce = true;
          context.shouldPop();

          Navigator.of(context).pushNamed(
            Routes.multiMatchReviewScreen,
            arguments: MultiMatchReviewScreenArgs(
              questions: widget.args.questions,
            ),
          );
        }
      });
    }

    return _buildButton(
      context.tr('reviewAnsBtn')!,
      () {
        if (_unlockedReviewAnswersOnce) {
          Navigator.of(context).pushNamed(
            Routes.multiMatchReviewScreen,
            arguments: MultiMatchReviewScreenArgs(
              questions: widget.args.questions,
            ),
          );
          return;
        }

        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            actions: [
              TextButton(
                onPressed: onTapYesReviewAnswers,
                child: Text(
                  context.tr(continueLbl)!,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),

              /// Cancel Button
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(
                  context.tr(cancelButtonKey)!,
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
            content: Text(
              '${context.read<SystemConfigCubit>().reviewAnswersDeductCoins} ${context.tr(coinsWillBeDeductedKey)!}',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        );
      },
      context,
    );
  }

  Widget _buildShareYourScoreButton() {
    Future<void> onTap() async {
      try {
        final image = await screenshotController.capture();
        final directory = (await getApplicationDocumentsDirectory()).path;

        final fileName = DateTime.now().microsecondsSinceEpoch.toString();
        final file = await File('$directory/$fileName.png').create();
        await file.writeAsBytes(image!.buffer.asUint8List());

        final appLink = context.read<SystemConfigCubit>().appUrl;

        final referralCode =
            context.read<UserDetailsCubit>().getUserProfile().referCode ?? '';

        final scoreText = '$kAppName'
            "\n${context.tr('myScoreLbl')!}"
            "\n${context.tr("appLink")!}"
            '\n$appLink'
            "\n${context.tr("useMyReferral")} $referralCode ${context.tr("toGetCoins")}";

        await UiUtils.share(
          scoreText,
          files: [XFile(file.path)],
          context: context,
        ).onError(
          (e, s) => ShareResult('$e', ShareResultStatus.dismissed),
        );
      } on Exception catch (_) {
        if (!mounted) return;

        UiUtils.showSnackBar(
          context.tr(
            convertErrorCodeToLanguageKey(errorCodeDefaultMessage),
          )!,
          context,
        );
      }
    }

    return Builder(
      builder: (context) {
        return _buildButton(
          context.tr('shareScoreBtn')!,
          onTap,
          context,
        );
      },
    );
  }

  Widget _buildHomeButton() {
    void onTapHomeButton() {
      _fetchUserDetails();
      context.pushNamedAndRemoveUntil(
        Routes.home,
        predicate: (_) => false,
      );
    }

    return _buildButton(
      context.tr('homeBtn')!,
      onTapHomeButton,
      context,
    );
  }
}
