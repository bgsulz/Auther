import 'package:flutter/material.dart';

/// Mixin that manages TextEditingController lifecycle for StatefulWidgets.
/// Extend your State class with this mixin and call [disposeControllers] in dispose.
///
/// Example usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ControllerMixin {
///   late final TextEditingController nameController;
///   late final TextEditingController emailController;
///
///   @override
///   void initState() {
///     super.initState();
///     nameController = createController();
///     emailController = createController(text: 'default@example.com');
///   }
///
///   @override
///   void dispose() {
///     disposeControllers();
///     super.dispose();
///   }
/// }
/// ```
mixin ControllerMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];

  /// Creates a TextEditingController and registers it for automatic disposal.
  /// Optionally accepts initial text.
  TextEditingController createController({String? text}) {
    final controller = TextEditingController(text: text);
    _controllers.add(controller);
    return controller;
  }

  /// Disposes all registered controllers.
  /// Call this in your State's dispose method.
  void disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

/// Extension to also manage FocusNodes with the same pattern.
mixin FocusNodeMixin<T extends StatefulWidget> on State<T> {
  final List<FocusNode> _focusNodes = [];

  /// Creates a FocusNode and registers it for automatic disposal.
  FocusNode createFocusNode() {
    final node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  /// Disposes all registered focus nodes.
  /// Call this in your State's dispose method.
  void disposeFocusNodes() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
  }
}
