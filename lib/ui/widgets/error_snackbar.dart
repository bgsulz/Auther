import 'package:flutter/material.dart';
import '../../models/result.dart';

/// Helper class for displaying consistent error feedback using Result types.
class ErrorSnackbar {
  ErrorSnackbar._();

  /// Shows an error snackbar if the result is a Failure.
  /// Returns true if an error was shown, false otherwise.
  static bool showIfError<T>(BuildContext context, Result<T> result) {
    if (result.isFailure) {
      showError(context, result.errorOrNull ?? 'An error occurred');
      return true;
    }
    return false;
  }

  /// Shows an error snackbar with the given message.
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success snackbar with the given message.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an info snackbar with the given message.
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handles a Result and shows appropriate feedback.
  /// Shows error snackbar on failure, optionally shows success snackbar on success.
  static void handleResult<T>(
    BuildContext context,
    Result<T> result, {
    String? successMessage,
    void Function(T value)? onSuccess,
  }) {
    result.when(
      success: (value) {
        if (successMessage != null) {
          showSuccess(context, successMessage);
        }
        onSuccess?.call(value);
      },
      failure: (message, _) {
        showError(context, message);
      },
    );
  }
}

/// Extension on Result for convenient snackbar display.
extension ResultSnackbarExtension<T> on Result<T> {
  /// Shows an error snackbar if this is a Failure.
  bool showErrorIfFailed(BuildContext context) {
    return ErrorSnackbar.showIfError(context, this);
  }
}
