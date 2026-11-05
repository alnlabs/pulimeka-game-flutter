import 'package:shared_preferences/shared_preferences.dart';

import '../models/hint_policy.dart';
import '../models/player_profile.dart';
import 'ad_config.dart';

enum HintAccess { tutorial, free, batch, needsAd }

/// Persists games played, free hints, and 3-hints-per-ad batches.
class HintService {
  HintService._();

  static final HintService instance = HintService._();

  static const _gamesCompletedKey = 'hint_games_completed';
  static const _freeHintsKey = 'hint_free_remaining';
  static const _initializedFreeKey = 'hint_free_bank_initialized';
  static const _batchHintsKey = 'hint_batch_remaining';
  static const _totalHintsUsedKey = 'hint_total_used';
  static const _firstPlayKey = 'player_first_play_ms';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _storage() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> ensureFirstPlayRecorded() async {
    final prefs = await _storage();
    if (!prefs.containsKey(_firstPlayKey)) {
      await prefs.setInt(_firstPlayKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<DateTime?> firstPlayDate() async {
    final prefs = await _storage();
    final ms = prefs.getInt(_firstPlayKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<int> gamesCompleted() async {
    final prefs = await _storage();
    return prefs.getInt(_gamesCompletedKey) ?? 0;
  }

  Future<int> totalHintsUsed() async {
    final prefs = await _storage();
    return prefs.getInt(_totalHintsUsedKey) ?? 0;
  }

  Future<bool> isTutorialPhase() async {
    return (await gamesCompleted()) < HintPolicy.tutorialGames;
  }

  Future<bool> shouldShowAutoHints() async => isTutorialPhase();

  Future<int> freeHintsRemaining() async {
    final prefs = await _storage();
    return prefs.getInt(_freeHintsKey) ?? 0;
  }

  Future<int> batchHintsRemaining() async {
    final prefs = await _storage();
    return prefs.getInt(_batchHintsKey) ?? 0;
  }

  Future<HintAccess> checkAccess() async {
    if (await isTutorialPhase()) {
      return HintAccess.tutorial;
    }
    if ((await freeHintsRemaining()) > 0) {
      return HintAccess.free;
    }
    if ((await batchHintsRemaining()) > 0) {
      return HintAccess.batch;
    }
    return HintAccess.needsAd;
  }

  Future<void> grantAdHintBatch() async {
    final prefs = await _storage();
    await prefs.setInt(_batchHintsKey, HintPolicy.hintsPerAdBatch);
  }

  Future<void> _incrementHintsUsed() async {
    final prefs = await _storage();
    final total = (prefs.getInt(_totalHintsUsedKey) ?? 0) + 1;
    await prefs.setInt(_totalHintsUsedKey, total);
  }

  /// Call when a hint is actually shown (not for tutorial auto-hints).
  Future<void> consumeHintOnUse() async {
    if (await isTutorialPhase()) {
      return;
    }
    await _incrementHintsUsed();

    final prefs = await _storage();
    final free = prefs.getInt(_freeHintsKey) ?? 0;
    if (free > 0) {
      await prefs.setInt(_freeHintsKey, free - 1);
      return;
    }

    final batch = prefs.getInt(_batchHintsKey) ?? 0;
    if (batch > 0) {
      await prefs.setInt(_batchHintsKey, batch - 1);
    }
  }

  @Deprecated('Use consumeHintOnUse')
  Future<void> consumeFreeHintIfNeeded() => consumeHintOnUse();

  Future<void> recordGameCompleted() async {
    final prefs = await _storage();
    await ensureFirstPlayRecorded();
    final completed = (prefs.getInt(_gamesCompletedKey) ?? 0) + 1;
    await prefs.setInt(_gamesCompletedKey, completed);

    final bankInitialized = prefs.getBool(_initializedFreeKey) ?? false;
    if (completed == HintPolicy.tutorialGames && !bankInitialized) {
      await prefs.setInt(_freeHintsKey, HintPolicy.freeHintsAfterTutorial);
      await prefs.setBool(_initializedFreeKey, true);
    }
  }

  Future<PlayerProfile> loadProfile() async {
    await ensureFirstPlayRecorded();
    final tutorial = await isTutorialPhase();
    final games = await gamesCompleted();
    final free = await freeHintsRemaining();
    final batch = await batchHintsRemaining();
    final total = await totalHintsUsed();
    final started = await firstPlayDate();

    String phaseLabel;
    String countSummary;
    if (tutorial) {
      final left = HintPolicy.tutorialGames - games;
      phaseLabel = 'Tutorial phase';
      countSummary = 'Auto hints · $left game${left == 1 ? '' : 's'} left in tutorial';
    } else if (free > 0) {
      phaseLabel = 'Free hints';
      countSummary = '$free free · then ${HintPolicy.hintsPerAdBatch} per ad';
    } else if (batch > 0) {
      phaseLabel = 'Hint pack active';
      countSummary = '$batch of ${HintPolicy.hintsPerAdBatch} left · $total used total';
    } else if (AdConfig.canUseRewardedAd || AdConfig.canLoadInterstitial) {
      phaseLabel = 'Watch ad for hints';
      countSummary =
          'Next ${HintPolicy.hintsPerAdBatch} hints need an ad · $total used total';
    } else {
      phaseLabel = 'More hints';
      countSummary =
          'Tap hint for ${HintPolicy.hintsPerAdBatch} more · $total used total';
    }

    return PlayerProfile(
      firstPlayDate: started,
      gamesCompleted: games,
      totalHintsUsed: total,
      freeHintsRemaining: free,
      batchHintsRemaining: batch,
      isTutorialPhase: tutorial,
      hintPhaseLabel: phaseLabel,
      hintCountSummary: countSummary,
    );
  }

  Future<String> statusLabel() async {
    final p = await loadProfile();
    if (p.isTutorialPhase) {
      final left = HintPolicy.tutorialGames - p.gamesCompleted;
      return 'Tutorial ($left left)';
    }
    if (p.freeHintsRemaining > 0) {
      return 'Hints: ${p.freeHintsRemaining} free';
    }
    if (p.batchHintsRemaining > 0) {
      return 'Hints: ${p.batchHintsRemaining}/${HintPolicy.hintsPerAdBatch}';
    }
    if (AdConfig.canUseRewardedAd || AdConfig.canLoadInterstitial) {
      return 'Hints: watch ad (${HintPolicy.hintsPerAdBatch})';
    }
    return 'Hints: +${HintPolicy.hintsPerAdBatch}';
  }
}
