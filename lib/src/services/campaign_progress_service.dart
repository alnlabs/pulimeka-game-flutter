import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign_level.dart';

/// Local level unlock + star progress.
class CampaignProgressService {
  CampaignProgressService._();
  static final instance = CampaignProgressService._();

  static const bool unlockAllLevels = false;

  static const _highestUnlockedKey = 'campaign_highest_unlocked';
  static const _starsPrefix = 'campaign_stars_';

  Future<int> highestUnlocked() async {
    if (unlockAllLevels) return CampaignLevels.count;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highestUnlockedKey) ?? 1;
  }

  Future<int> starsFor(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_starsPrefix$levelId') ?? 0;
  }

  Future<Map<int, int>> allStars() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <int, int>{};
    for (final level in CampaignLevels.all) {
      map[level.id] = prefs.getInt('$_starsPrefix${level.id}') ?? 0;
    }
    return map;
  }

  static const int maxStars = CampaignLevels.count * 3;

  Future<int> totalStars() async {
    final all = await allStars();
    return all.values.fold<int>(0, (sum, stars) => sum + stars);
  }

  /// Next playable stage (highest unlocked).
  Future<int> continueLevelId() => highestUnlocked();

  static String starCriteriaHint({required bool humanIsGoat}) {
    if (humanIsGoat) {
      return '3★ no goats lost · 2★ few captures · 1★ you trapped the tigers';
    }
    return '3★ win with goats still on the board · 2★ if the herd is wiped';
  }

  /// Returns stars awarded (1–3). Unlocks next level on first clear.
  Future<int> recordWin({
    required int levelId,
    required int capturedGoats,
    required int goatsToCapture,
    required bool humanIsGoat,
    int goatsOnBoard = 0,
  }) async {
    final stars = _computeStars(
      capturedGoats: capturedGoats,
      goatsToCapture: goatsToCapture,
      humanIsGoat: humanIsGoat,
      goatsOnBoard: goatsOnBoard,
    );
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getInt('$_starsPrefix$levelId') ?? 0;
    if (stars > prev) {
      await prefs.setInt('$_starsPrefix$levelId', stars);
    }
    final unlocked = prefs.getInt(_highestUnlockedKey) ?? 1;
    if (levelId >= unlocked && levelId < CampaignLevels.count) {
      await prefs.setInt(_highestUnlockedKey, levelId + 1);
    }
    return stars;
  }

  int _computeStars({
    required int capturedGoats,
    required int goatsToCapture,
    required bool humanIsGoat,
    int goatsOnBoard = 0,
  }) {
    if (humanIsGoat) {
      if (capturedGoats == 0) return 3;
      if (capturedGoats <= (goatsToCapture / 3).ceil()) return 2;
      return 1;
    }
    // Human tiger: quota win with herd still on the board = 3, wipe = 2.
    return goatsOnBoard > 0 ? 3 : 2;
  }
}
