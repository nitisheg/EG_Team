import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/ads/blocs/banner_ad_cubit.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdContainer extends StatefulWidget {
  const BannerAdContainer({super.key});

  @override
  State<BannerAdContainer> createState() => _BannerAdContainer();
}

class _BannerAdContainer extends State<BannerAdContainer> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<BannerAdCubit>().initBannerAd(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerAdCubit, BannerAdState>(
      builder: (context, state) {
        final sysConfig = context.read<SystemConfigCubit>();
        if (sysConfig.isAdsEnable &&
            !context.read<UserDetailsCubit>().removeAds()) {
          if (sysConfig.adsType == 1) {
            if (state is BannerAdLoaded) {
              final bannerAd = context.read<BannerAdCubit>().googleBannerAd;
              if (bannerAd != null) {
                return SizedBox(
                  width: context.width,
                  height: bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: bannerAd),
                );
              }
            }
          } else {
            if (state is BannerAdLoaded) {
              final unityBannerAd = context.read<BannerAdCubit>().unityBannerAd;
              if (unityBannerAd != null) {
                return unityBannerAd;
              }
            }
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
