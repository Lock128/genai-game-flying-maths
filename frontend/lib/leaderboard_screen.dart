import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LeaderboardScreen extends StatelessWidget {
  final VoidCallback onBack;
  final List<Map<String, dynamic>> leaderboardEntries;

  const LeaderboardScreen({
    Key? key,
    required this.onBack,
    required this.leaderboardEntries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.leaderboard),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardEntries.length,
              itemBuilder: (context, index) {
                final entry = leaderboardEntries[index];
                final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime.parse(entry['date']),
                );
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(entry['playerName'] ?? 'Anonymous'),
                    subtitle: Text('Score: ${entry['score']} • Speed: ${entry['completionTime']}s'),
                    trailing: Text(dateStr),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}