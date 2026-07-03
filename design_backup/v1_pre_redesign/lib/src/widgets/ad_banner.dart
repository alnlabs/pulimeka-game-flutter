import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';
import '../theme/app_theme.dart';

/// Bottom banner slot matching Android `AdBanner` (50dp, full width).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdConfig.shouldRequestLiveAds) {
      return;
    }

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _failed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: ${error.message}');
          if (!mounted) return;
          setState(() {
            _loaded = false;
            _failed = true;
          });
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.shouldShowAds) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: AdConfig.bannerHeight,
      child: _loaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : _AdBannerPlaceholder(
              loading: !_failed && AdConfig.shouldRequestLiveAds,
              failed: _failed || !AdConfig.shouldRequestLiveAds,
            ),
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({
    required this.loading,
    required this.failed,
  });

  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLighter,
        border: Border.all(color: AppTheme.textTertiary.withOpacity(0.35)),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ads_click,
                    size: 18,
                    color: AppTheme.textTertiary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _placeholderLabel(failed),
                    style: AppTheme.text(
                      size: 12,
                      weight: FontWeight.w500,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _placeholderLabel(bool failed) {
  if (!AdConfig.shouldRequestLiveAds &&
      defaultTargetPlatform == TargetPlatform.iOS) {
    return 'Ad slot (iOS Release)';
  }
  if (failed) {
    return 'Ad placeholder';
  }
  return 'Advertisement';
}
