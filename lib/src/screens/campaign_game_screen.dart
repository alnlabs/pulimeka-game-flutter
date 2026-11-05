import 'package:flutter/material.dart';

import '../controllers/ai_game_controller.dart';
import '../models/campaign_level.dart';
import '../widgets/offline_game_view.dart';

class CampaignGameScreen extends StatefulWidget {
  const CampaignGameScreen({required this.levelId, super.key});

  static const routeName = '/campaign-play';

  final int levelId;

  @override
  State<CampaignGameScreen> createState() => _CampaignGameScreenState();
}

class _CampaignGameScreenState extends State<CampaignGameScreen> {
  late int _levelId = widget.levelId;

  void _goNext(CampaignLevel current) {
    if (current.id >= CampaignLevels.count) {
      Navigator.pop(context);
      return;
    }
    setState(() => _levelId = current.id + 1);
  }

  @override
  Widget build(BuildContext context) {
    final level = CampaignLevels.byId(_levelId);
    final humanIsGoat = level.humanIsGoat;
    final tigerName = humanIsGoat ? 'AI (Tigers)' : 'You (Tigers)';
    final goatName = humanIsGoat ? 'You (Goats)' : 'AI (Goats)';

    return OfflineGameView(
      key: ValueKey('campaign-${level.id}'),
      tigerPlayerName: tigerName,
      goatPlayerName: goatName,
      modeLabel: 'Level ${level.id} · ${level.title}',
      aiHumanRole: level.humanSide,
      aiHumanName: 'You',
      campaignLevel: level,
      onCampaignNext: () => _goNext(level),
      controller: AiGameController(
        humanRole: level.humanSide,
        difficulty: level.ai,
        engine: level.createEngine(),
      ),
    );
  }
}
