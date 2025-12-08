import 'package:flutter/foundation.dart';

/// Authentication provider for managing PIN-based authentication
class AuthProvider extends ChangeNotifier {
  // Authentication state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // PIN input
  String _pinInput = '';

  // TODO: Replace with actual stored PIN from settings/database
  static const String _storedPin = '2856';

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get pinInput => _pinInput;

  /// Update PIN input
  void updatePin(String pin) {
    _pinInput = pin;
    // Clear error when user types
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear PIN input
  void clearPin() {
    _pinInput = '';
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate and authenticate with PIN
  Future<bool> login(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network/database delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Validate PIN format
      if (pin.isEmpty) {
        _errorMessage = 'Please enter your PIN';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (pin.length != 4) {
        _errorMessage = 'PIN must be exactly 4 digits';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
        _errorMessage = 'PIN must contain only numbers';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // TODO: Replace with actual authentication logic
      // This could involve:
      // - Checking against stored PIN in database
      // - Hashing and comparing PINs securely
      // - Rate limiting failed attempts
      // - Logging authentication attempts

      if (pin == _storedPin) {
        // Authentication successful
        _isAuthenticated = true;
        _errorMessage = null;
        _pinInput = '';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Authentication failed
        _errorMessage = 'Invalid PIN. Please try again.';
        _pinInput = '';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  void logout() {
    _isAuthenticated = false;
    _pinInput = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset authentication state (for testing)
  void reset() {
    _isAuthenticated = false;
    _isLoading = false;
    _errorMessage = null;
    _pinInput = '';
    notifyListeners();
  }
}
