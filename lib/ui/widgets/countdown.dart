import '../../customization/config.dart';
import '../../state/auther_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountdownBar extends StatelessWidget {
  const CountdownBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AutherState>();

    // If ticker hasn't started yet, show indeterminate.
    if (appState.seed == 0) {
      return const LinearProgressIndicator();
    }

    final currentProgress = appState.progress.clamp(0.0, 1.0);
    final remainingMs = (currentProgress * Config.intervalMillis).clamp(0, Config.intervalMillis);

    return TweenAnimationBuilder<double>(
      key: ValueKey(appState.seed),
      tween: Tween<double>(begin: currentProgress, end: 0),
      duration: Duration(milliseconds: remainingMs.round()),
      curve: Curves.linear,
      builder: (context, value, _) => LinearProgressIndicator(value: value),
    );
  }
}
