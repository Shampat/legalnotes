import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class AdManager {
  static BannerAd? _bannerAd;
  static bool _isBannerLoaded = false;

  static NativeAd? _nativeAd;
  static bool _isNativeLoaded = false;

  static Future<void> loadAdaptiveBanner() async {
    await Future.delayed(const Duration(seconds: 10));

    final width = WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;

    final anchoredAdaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());

    if (anchoredAdaptiveSize == null) return;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: anchoredAdaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          final banner = ad as BannerAd;
          print('Adaptive banner loaded: ${banner.size.width}x${banner.size.height}');
        },
        onAdFailedToLoad: (ad, error) {
          print('Adaptive banner failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  static Widget getBannerAdWidget() {
    if (!_isBannerLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: double.infinity,
      child: AdWidget(ad: _bannerAd!),
    );
  }

  static Future<void> loadNativeAd() async {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile', // We'll create this factory next
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeLoaded = true;
          print('Native ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  static Widget getNativeAdWidget() {
    if (!_isNativeLoaded || _nativeAd == null) return const SizedBox.shrink();
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: AdWidget(ad: _nativeAd!),
    );
  }

  static bool shouldShowBannerOnDashboard(bool hasNative) {
    return !hasNative; // Hide banner if native is shown
  }

  static void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    _bannerAd = null;
    _nativeAd = null;
    _isBannerLoaded = false;
    _isNativeLoaded = false;
  }
}
