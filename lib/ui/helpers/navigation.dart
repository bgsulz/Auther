import 'package:flutter/material.dart';

/// Helper class for safe navigation operations.
/// Ensures mounted state is checked before navigation to prevent errors
/// when navigating after async operations.
class SafeNavigation {
  SafeNavigation._();

  /// Safely navigate to a named route.
  /// Only navigates if the context is still mounted.
  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    if (context.mounted) {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
  }

  /// Safely replace current route with a named route.
  /// Only navigates if the context is still mounted.
  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    }
  }

  /// Safely pop the current route.
  /// Only pops if the context is still mounted.
  static void pop<T>(BuildContext context, [T? result]) {
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  /// Safely pop until reaching a route matching the predicate.
  /// Only navigates if the context is still mounted.
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    if (context.mounted) {
      Navigator.of(context).popUntil(predicate);
    }
  }

  /// Safely push and remove all routes until predicate.
  /// Only navigates if the context is still mounted.
  static void pushNamedAndRemoveUntil(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        routeName,
        predicate,
        arguments: arguments,
      );
    }
  }

  /// Safely check if navigator can pop.
  static bool canPop(BuildContext context) {
    if (!context.mounted) return false;
    return Navigator.of(context).canPop();
  }
}

/// Extension on BuildContext for convenient safe navigation.
extension SafeNavigationExtension on BuildContext {
  /// Safely navigate to a named route.
  void safeNavigateTo(String routeName, {Object? arguments}) {
    SafeNavigation.pushNamed(this, routeName, arguments: arguments);
  }

  /// Safely replace current route with a named route.
  void safeReplaceTo(String routeName, {Object? arguments}) {
    SafeNavigation.pushReplacementNamed(this, routeName, arguments: arguments);
  }

  /// Safely pop the current route.
  void safePop<T>([T? result]) {
    SafeNavigation.pop(this, result);
  }
}
