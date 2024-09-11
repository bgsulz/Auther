import 'package:auther/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountdownBar extends StatefulWidget {
  const CountdownBar({
    super.key,
  });

  @override
  CountdownBarState createState() => CountdownBarState();
}

class CountdownBarState extends State<CountdownBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  late AutherState appState;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AutherState>(context, listen: false);
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: AutherState.refreshIntervalSeconds),
        upperBound: 1,
        lowerBound: 0,
        reverseDuration:
            Duration(milliseconds: AutherState.refreshIntervalSeconds * 1000),
        value: appState.getProgress());
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_animationController.value <= 0) {
          _animationController.value = appState.getProgress();
          _animationController.reverse();
        }
        return LinearProgressIndicator(
          value: _animationController.value,
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
