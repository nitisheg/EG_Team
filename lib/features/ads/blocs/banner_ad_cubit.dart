import 'dart:developer';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/features/profile_management/cubits/user_details_cubit.dart';
import 'package:flutterquiz/features/system_config/cubits/system_config_cubit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

abstract class BannerAdState {}

class BannerAdInitial extends BannerAdState {}

class BannerAdLoaded extends BannerAdState {}

class BannerAdLoadInProgress extends BannerAdState {}

class BannerAdFailure extends BannerAdState {}

class BannerAdCubit extends Cubit<BannerAdState> {
  BannerAdCubit() : super(BannerAdInitial());

  BannerAd? _googleBannerAd;
  UnityBannerAd? _unityBannerAd;

  BannerAd? get googleBannerAd => _googleBannerAd;
  UnityBannerAd? get unityBannerAd => _unityBannerAd;

  void _createGoogleBannerAd(BuildContext context) {
    _googleBannerAd?.dispose();
    final banner = BannerAd(
      request: const AdRequest(),
      adUnitId: context.read<SystemConfigCubit>().googleBannerId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _googleBannerAd = ad as BannerAd;
          emit(BannerAdLoaded());
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('$BannerAd failedToLoad: $error');
          emit(BannerAdFailure());
        },
        onAdOpened: (Ad ad) => log('$BannerAd onAdOpened'),
        onAdClosed: (Ad ad) => log('$BannerAd onAdClosed'),
      ),
      size: AdSize.banner,
    );
    banner.load();
  }

  void _createUnityBannerAd() {
    _unityBannerAd = UnityBannerAd(
      placementId: unityBannerAdsPlacement(),
      onLoad: (placementId) {
        log('Banner loaded: $placementId');
        emit(BannerAdLoaded());
      },
      onClick: (placementId) => log('Banner clicked: $placementId'),
      onFailed: (placementId, error, message) {
        log('Banner Ad $placementId failed: $error $message');
        emit(BannerAdFailure());
      },
    );
  }

  void initBannerAd(BuildContext context) {
    final systemConfigCubit = context.read<SystemConfigCubit>();
    if (systemConfigCubit.isAdsEnable &&
        !context.read<UserDetailsCubit>().removeAds()) {
      if (systemConfigCubit.adsType == 1) {
        _createGoogleBannerAd(context);
      } else {
        _createUnityBannerAd();
      }
    }
  }

  String unityBannerAdsPlacement() {
    if (Platform.isAndroid) {
      return 'Banner_Android';
    }
    if (Platform.isIOS) {
      return 'Banner_iOS';
    }
    return '';
  }

  bool get bannerAdLoaded => state is BannerAdLoaded;

  @override
  Future<void> close() async {
    await _googleBannerAd?.dispose();
    return super.close();
  }
}
