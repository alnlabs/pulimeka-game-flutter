/// AI strength settings (aligned with Android `AIPlayer` / `DifficultyConfig`).
enum AiDifficulty {
  /// Intentionally weak — early teaching levels only.
  tutorial,
  easy,
  medium,
  hard;

  static AiDifficulty parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'tutorial':
        return AiDifficulty.tutorial;
      case 'easy':
        return AiDifficulty.easy;
      case 'hard':
        return AiDifficulty.hard;
      default:
        return AiDifficulty.medium;
    }
  }

  String get label {
    switch (this) {
      case AiDifficulty.tutorial:
        return 'Tutorial';
      case AiDifficulty.easy:
        return 'Easy';
      case AiDifficulty.medium:
        return 'Medium';
      case AiDifficulty.hard:
        return 'Hard';
    }
  }

  int get searchDepth {
    switch (this) {
      case AiDifficulty.tutorial:
        return 1;
      case AiDifficulty.easy:
        return 2;
      case AiDifficulty.medium:
        return 3;
      case AiDifficulty.hard:
        return 4;
    }
  }

  double get randomMoveChance {
    switch (this) {
      case AiDifficulty.tutorial:
        return 0.75;
      case AiDifficulty.easy:
        return 0.35;
      case AiDifficulty.medium:
        return 0.1;
      case AiDifficulty.hard:
        return 0;
    }
  }

  /// Max think time per move (Android `DifficultyConfig.timeLimit`).
  int get timeLimitMs {
    switch (this) {
      case AiDifficulty.tutorial:
        return 400;
      case AiDifficulty.easy:
        return 1000;
      case AiDifficulty.medium:
        return 2000;
      case AiDifficulty.hard:
        return 3000;
    }
  }

  Duration get thinkDelay {
    switch (this) {
      case AiDifficulty.tutorial:
        return const Duration(milliseconds: 350);
      case AiDifficulty.easy:
        return const Duration(milliseconds: 500);
      case AiDifficulty.medium:
        return const Duration(milliseconds: 500);
      case AiDifficulty.hard:
        return const Duration(milliseconds: 300);
    }
  }
}
