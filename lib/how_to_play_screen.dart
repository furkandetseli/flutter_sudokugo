import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HowToPlayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.howToPlay),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.sudokuRules,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.rule1),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.rule2),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.rule3),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.tips,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.tip1),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.tip2),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.tip3),
          ],
        ),
      ),
    );
  }
}