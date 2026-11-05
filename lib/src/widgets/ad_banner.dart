import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_config.dart';
import '../services/ad_request_helper.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../utils/ad_load_retry.dart';

/// Anchored banner for any [Scaffold.bottomNavigationBar].
class ScreenAdBar extends StatelessWidget {
  const ScreenAdBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.shouldShowAds) {
      return const SizedBox.shrink();
    }
    return const Material(
      color: AppTheme.background,
      child: AdBanner(safeBottom: true),
    );
  }
}

/// Bottom banner slot matching Android `AdBanner` (adaptive width, retries on fail).
class AdBanner extends StatefulWidget {
  const AdBanner({this.safeBottom = false, super.key});

  /// Add home-indicator padding only when a real ad is showing.
  final bool safeBottom;

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
    if (!AdConfig.shouldShowAds ||
        !AdConfig.shouldLoadAds ||
        !_loaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final height = (_adSize?.height.toDouble() ?? AdConfig.bannerHeight)
        .clamp(AdConfig.bannerHeight, 120.0);

    final banner = SizedBox(
      width: double.infinity,
      height: height,
      child: AdWidget(ad: _bannerAd!),
    );
    if (!widget.safeBottom) {
      return banner;
    }
    return SafeArea(top: false, child: banner);
  }
}
