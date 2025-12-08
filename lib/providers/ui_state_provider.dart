import 'package:flutter/foundation.dart';

/// Provider for global UI state management
/// Manages loading overlays, error messages, and success notifications
class UIStateProvider extends ChangeNotifier {
  bool _isGlobalLoading = false;
  String? _globalError;
  String? _successMessage;
  String? _infoMessage;

  // Auto-dismiss timer duration (in seconds)
  static const int _autoDismissDuration = 3;

  // Getters
  bool get isGlobalLoading => _isGlobalLoading;
  String? get globalError => _globalError;
  String? get successMessage => _successMessage;
  String? get infoMessage => _infoMessage;

  bool get hasError => _globalError != null;
  bool get hasSuccess => _successMessage != null;
  bool get hasInfo => _infoMessage != null;
  bool get hasMessage => hasError || hasSuccess || hasInfo;

  /// Show global loading overlay
  void showLoading([String? message]) {
    _isGlobalLoading = true;
    notifyListeners();
  }

  /// Hide global loading overlay
  void hideLoading() {
    _isGlobalLoading = false;
    notifyListeners();
  }

  /// Show error message
  void showError(String message, {bool autoDismiss = true}) {
    _globalError = message;
    _successMessage = null; // Clear success message
    _infoMessage = null; // Clear info message
    notifyListeners();

    if (autoDismiss) {
      Future.delayed(
        Duration(seconds: _autoDismissDuration),
        () => clearError(),
      );
    }
  }

  /// Show success message
  void showSuccess(String message, {bool autoDismiss = true}) {
    _successMessage = message;
    _globalError = null; // Clear error message
    _infoMessage = null; // Clear info message
    notifyListeners();

    if (autoDismiss) {
      Future.delayed(
        Duration(seconds: _autoDismissDuration),
        () => clearSuccess(),
      );
    }
  }

  /// Show info message
  void showInfo(String message, {bool autoDismiss = true}) {
    _infoMessage = message;
    _globalError = null; // Clear error message
    _successMessage = null; // Clear success message
    notifyListeners();

    if (autoDismiss) {
      Future.delayed(
        Duration(seconds: _autoDismissDuration),
        () => clearInfo(),
      );
    }
  }

  /// Clear error message
  void clearError() {
    if (_globalError != null) {
      _globalError = null;
      notifyListeners();
    }
  }

  /// Clear success message
  void clearSuccess() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Clear info message
  void clearInfo() {
    if (_infoMessage != null) {
      _infoMessage = null;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    bool hasChanges = _globalError != null ||
                      _successMessage != null ||
                      _infoMessage != null;

    if (hasChanges) {
      _globalError = null;
      _successMessage = null;
      _infoMessage = null;
      notifyListeners();
    }
  }

  /// Clear all state (loading and messages)
  void clearAll() {
    _isGlobalLoading = false;
    _globalError = null;
    _successMessage = null;
    _infoMessage = null;
    notifyListeners();
  }
}
