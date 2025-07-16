import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/commons/commons.dart';
import 'package:flutterquiz/core/core.dart';
import 'package:flutterquiz/features/ads/blocs/banner_ad_cubit.dart';
import 'package:flutterquiz/features/ads/blocs/interstitial_ad_cubit.dart';
import 'package:flutterquiz/features/ads/widgets/banner_ad_container.dart';
import 'package:flutterquiz/features/quiz/cubits/quiz_category_cubit.dart';
import 'package:flutterquiz/features/quiz/models/category.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/ui/screens/quiz/multi_match/screens/multi_match_quiz_screen.dart';
import 'package:flutterquiz/ui/widgets/already_logged_in_dialog.dart';
import 'package:flutterquiz/ui/widgets/circular_progress_container.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/ui/widgets/error_container.dart';
import 'package:flutterquiz/ui/widgets/premium_category_access_badge.dart';
import 'package:flutterquiz/ui/widgets/unlock_premium_category_dialog.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({required this.quizType, super.key});

  final QuizTypes quizType;

  @override
  State<CategoryScreen> createState() => _CategoryScreen();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments! as Map;
    return CupertinoPageRoute(
      builder: (_) => CategoryScreen(
        quizType: arguments['quizType'] as QuizTypes,
        // categoryName: arguments['categoryName'],
      ),
    );
  }
}

class _CategoryScreen extends State<CategoryScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // preload ads
    Future.delayed(Duration.zero, () {
      context.read<InterstitialAdCubit>().showAd(context);
    });

    context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
          languageId: UiUtils.getCurrentQuizLanguageId(context),
          type: UiUtils.getCategoryTypeNumberFromQuizType(widget.quizType),
        );
  }

  String getCategoryTitle(QuizTypes quizType) => context.tr(
        switch (quizType) {
          QuizTypes.mathMania => 'mathMania',
          QuizTypes.audioQuestions => 'audioQuestions',
          QuizTypes.guessTheWord => 'guessTheWord',
          QuizTypes.funAndLearn => 'funAndLearn',
          QuizTypes.multiMatch => 'multiMatch',
          _ => 'quizZone',
        },
      )!;

  @override
  Widget build(BuildContext context) {
    final bannerAdLoaded = context.watch<BannerAdCubit>().bannerAdLoaded;
    return Scaffold(
      appBar: QAppBar(title: Text(getCategoryTitle(widget.quizType))),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bannerAdLoaded ? 60 : 0),
            child: showCategory(),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BannerAdContainer(),
          ),
        ],
      ),
    );
  }

  void _handleOnTapCategory(BuildContext context, Category category) {
    /// Unlock the Premium Category
    if (category.isPremium &&
        !category.hasUnlocked &&
        !category.hasSubcategories &&
        !category.hasLevels) {
      showUnlockPremiumCategoryDialog(
        context,
        categoryId: category.id!,
        categoryName: category.categoryName!,
        requiredCoins: category.requiredCoins,
      );
      return;
    }

    /// noOf is number of subcategories
    if (!category.hasSubcategories) {
      if (widget.quizType == QuizTypes.multiMatch) {
        if (category.maxLevel == '0') {
          Navigator.of(context).pushNamed(
            Routes.multiMatchQuiz,
            arguments: MultiMatchQuizArgs(
              categoryId: category.id!,
              isPremiumCategory: category.isPremium,
            ),
          );
        } else {
          Navigator.of(context).pushNamed(
            Routes.levels,
            arguments: {
              'Category': category,
              'quizType': QuizTypes.multiMatch,
            },
          );
        }
      } else if (widget.quizType == QuizTypes.quizZone) {
        /// if category doesn't have any subCategory, check for levels.
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
              'isPremiumCategory': category.isPremium,
            },
          );
        } else {
          //navigate to level screen
          Navigator.of(context).pushNamed(
            Routes.levels,
            arguments: {
              'Category': category,
              'quizType': QuizTypes.quizZone,
            },
          );
        }
      } else if (widget.quizType == QuizTypes.audioQuestions) {
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'numberOfPlayer': 1,
            'quizType': QuizTypes.audioQuestions,
            'categoryId': category.id,
            'isPlayed': category.isPlayed,
            'isPremiumCategory': category.isPremium,
          },
        );
      } else if (widget.quizType == QuizTypes.guessTheWord) {
        Navigator.of(context).pushNamed(
          Routes.guessTheWord,
          arguments: {
            'type': 'category',
            'typeId': category.id,
            'isPlayed': category.isPlayed,
            'isPremiumCategory': category.isPremium,
          },
        );
      } else if (widget.quizType == QuizTypes.funAndLearn) {
        Navigator.of(context).pushNamed(
          Routes.funAndLearnTitle,
          arguments: {
            'type': 'category',
            'typeId': category.id,
            'title': category.categoryName,
            'isPremiumCategory': category.isPremium,
          },
        );
      } else if (widget.quizType == QuizTypes.mathMania) {
        Navigator.of(context).pushNamed(
          Routes.quiz,
          arguments: {
            'numberOfPlayer': 1,
            'quizType': QuizTypes.mathMania,
            'categoryId': category.id,
            'isPlayed': category.isPlayed,
            'isPremiumCategory': category.isPremium,
          },
        );
      }
    } else {
      if (widget.quizType == QuizTypes.multiMatch) {
        Navigator.of(context).pushNamed(
          Routes.subcategoryAndLevel,
          arguments: {
            'category': category,
            'quizType': QuizTypes.multiMatch,
          },
        );
      } else if (widget.quizType == QuizTypes.quizZone) {
        Navigator.of(context).pushNamed(
          Routes.subcategoryAndLevel,
          arguments: {
            'category': category,
            'quizType': QuizTypes.quizZone,
          },
        );
      } else {
        Navigator.of(context).pushNamed(
          Routes.subCategory,
          arguments: {
            'quizType': widget.quizType,
            'category': category,
          },
        );
      }
    }
  }

  Widget showCategory() {
    return BlocConsumer<QuizCategoryCubit, QuizCategoryState>(
      bloc: context.read<QuizCategoryCubit>(),
      listener: (context, state) {
        if (state is QuizCategoryFailure) {
          if (state.errorMessage == errorCodeUnauthorizedAccess) {
            showAlreadyLoggedInDialog(context);
          }
        }
      },
      builder: (context, state) {
        if (state is QuizCategoryProgress || state is QuizCategoryInitial) {
          return const Center(child: CircularProgressContainer());
        }
        if (state is QuizCategoryFailure) {
          return ErrorContainer(
            showBackButton: false,
            errorMessageColor: Theme.of(context).primaryColor,
            showErrorImage: true,
            errorMessage: convertErrorCodeToLanguageKey(state.errorMessage),
            onTapRetry: () {
              context.read<QuizCategoryCubit>().getQuizCategoryWithUserId(
                    languageId: UiUtils.getCurrentQuizLanguageId(context),
                    type: UiUtils.getCategoryTypeNumberFromQuizType(
                      widget.quizType,
                    ),
                  );
            },
          );
        }
        final categoryList = (state as QuizCategorySuccess).categories;
        return ListView.separated(
          padding: EdgeInsets.symmetric(
            vertical: context.height * UiUtils.vtMarginPct,
            horizontal: context.width * UiUtils.hzMarginPct,
          ),
          controller: scrollController,
          shrinkWrap: true,
          itemCount: categoryList.length,
          physics: const AlwaysScrollableScrollPhysics(),
          separatorBuilder: (_, i) =>
              const SizedBox(height: UiUtils.listTileGap),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _handleOnTapCategory(context, categoryList[index]),
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final colorScheme = Theme.of(context).colorScheme;

                  final imageUrl = categoryList[index].image!.isEmpty
                      ? Assets.placeholder
                      : categoryList[index].image!;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: boxConstraints.maxWidth * 0.1,
                        right: boxConstraints.maxWidth * 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: const [
                              BoxShadow(
                                offset: Offset(0, 25),
                                blurRadius: 5,
                                spreadRadius: 2,
                                color: Color(0x40808080),
                              ),
                            ],
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(
                                boxConstraints.maxWidth * .525,
                              ),
                            ),
                          ),
                          width: boxConstraints.maxWidth,
                          height: 50,
                        ),
                      ),
                      Positioned(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(12),
                          width: boxConstraints.maxWidth,
                          child: Row(
                            children: [
                              /// Leading Image
                              Align(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: colorScheme.onTertiary
                                          .withValues(alpha: 0.1),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(1),
                                    child: QImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              /// title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryList[index].categoryName!,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: colorScheme.onTertiary,
                                        fontSize: 18,
                                        fontWeight: FontWeights.semiBold,
                                      ),
                                    ),
                                    Text(
                                      !categoryList[index].hasSubcategories
                                          ? "${context.tr(
                                              widget.quizType ==
                                                      QuizTypes.funAndLearn
                                                  ? "comprehensiveLbl"
                                                  : "questions",
                                            )!}: ${categoryList[index].questionsCount}"
                                          : "${context.tr("subCategoriesLbl")!}: ${categoryList[index].subcategoriesCount}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onTertiary
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              /// right arrow
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PremiumCategoryAccessBadge(
                                    hasUnlocked:
                                        categoryList[index].hasUnlocked,
                                    isPremium: categoryList[index].isPremium,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: colorScheme.onTertiary
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Icon(
                                      context.isRTL
                                          ? Icons.keyboard_arrow_left_rounded
                                          : Icons.keyboard_arrow_right_rounded,
                                      size: 30,
                                      color: colorScheme.onTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
