import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Provider for navigation state management
/// Manages current route and provides navigation helpers
class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/';

  // Getter
  String get currentRoute => _currentRoute;

  /// Update current route
  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  /// Navigate to a route
  void navigateTo(String route, BuildContext context) {
    context.go(route);
    setCurrentRoute(route);
  }

  /// Navigate to upload page
  void goToUpload(BuildContext context) {
    navigateTo('/upload', context);
  }

  /// Navigate to asset detail page
  void goToAssetDetail(String slug, BuildContext context) {
    navigateTo('/asset/$slug', context);
  }

  /// Navigate to category listing page
  void goToCategory(String slug, BuildContext context) {
    navigateTo('/category/$slug', context);
  }

  /// Navigate to home page
  void goToHome(BuildContext context) {
    navigateTo('/', context);
  }

  /// Navigate back
  void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      goToHome(context);
    }
  }
}
