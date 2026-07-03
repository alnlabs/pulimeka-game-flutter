import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';
import '../services/ad_request_helper.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../utils/ad_load_retry.dart';

/// Bottom banner slot matching Android `AdBanner` (adaptive width, retries on fail).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _loaded = false;
  bool _failed = false;
  bool _loading = false;
  int _retryAttempt = 0;
  bool _useStandardBanner = false;
  static const int _maxRetries = 12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _failed && mounted) {
      _retryAttempt = 0;
      _startLoad();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_loading) {
      _startLoad();
    }
  }

  Future<void> _startLoad() async {
    if (!AdConfig.shouldLoadAds || _loading) return;
    _loading = true;
    try {
      await AdService.ensureInitialized();
      if (!mounted) return;
      await _loadAd();
    } finally {
      _loading = false;
    }
  }

  Future<void> _loadAd() async {
    if (!AdConfig.shouldLoadAds) return;

    _bannerAd?.dispose();
    _bannerAd = null;
    _loaded = false;

    final AdSize size;
    if (_useStandardBanner) {
      size = AdSize.banner;
    } else {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      size = adaptive ?? AdSize.banner;
    }
    _adSize = size;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: size,
      request: AdRequestHelper.build(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _failed = false;
            _retryAttempt = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(
            'Banner ad failed (${error.code}): ${error.message} '
            'domain=${error.domain}',
          );
          if (!mounted) return;
          setState(() {
            _loaded = false;
            _failed = true;
            _bannerAd = null;
            _useStandardBanner = !_useStandardBanner;
          });
          _scheduleRetry();
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  void _scheduleRetry() {
    _retryAttempt++;
    if (_retryAttempt > _maxRetries) return;
    final delay = adRetryDelay(_retryAttempt);
    Future<void>.delayed(delay, () {
      if (!mounted || !AdConfig.shouldLoadAds) return;
      _startLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.shouldShowAds) {
      return const SizedBox.shrink();
    }

    final height = (_adSize?.height.toDouble() ?? AdConfig.bannerHeight)
        .clamp(AdConfig.bannerHeight, 120.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: _loaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : _AdBannerPlaceholder(
              loading: !_failed && AdConfig.shouldLoadAds,
              failed: _failed || !AdConfig.shouldLoadAds,
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
  if (failed) {
    return 'Ad unavailable';
  }
  if (!AdConfig.shouldRequestLiveAds) {
    return 'Test ad';
  }
  return 'Advertisement';
}
