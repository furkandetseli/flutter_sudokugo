import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'statistics_service.dart';
import 'game_statistics.dart';

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
      ),
      body: FutureBuilder<GameStatistics>(
        future: StatisticsService.loadStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final stats = snapshot.data!;
            return _buildStatisticsView(context, stats);
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildStatisticsView(BuildContext context, GameStatistics stats) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildStatCard(
          context,
          icon: Icons.games,
          title: localizations.gamesPlayed,
          value: '${stats.gamesPlayed}',
        ),
        _buildStatCard(
          context,
          icon: Icons.emoji_events,
          title: localizations.gamesWon,
          value: '${stats.gamesWon}',
        ),
        _buildStatCard(
          context,
          icon: Icons.cancel,
          title: localizations.gamesLost,
          value: '${stats.gamesLost}',
        ),
        _buildStatCard(
          context,
          icon: Icons.timer,
          title: localizations.bestTime,
          value: _formatTime(stats.bestTime),
        ),
        _buildStatCard(
          context,
          icon: Icons.lightbulb,
          title: localizations.totalHintsUsed,
          value: '${stats.totalHintsUsed}',
        ),
        _buildStatCard(
          context,
          icon: Icons.check_circle,
          title: localizations.totalCorrectMoves,
          value: '${stats.totalCorrectMoves}',
        ),
        _buildStatCard(
          context,
          icon: Icons.error,
          title: localizations.totalMistakes,
          value: '${stats.totalMistakes}',
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.primaryColor),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}