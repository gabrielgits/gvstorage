/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'GvStorage';
  static const String appTagline = 'Digital Asset Management System';
  static const String copyright = 'Copyright © 2025 FM. All Rights Reserved.';
  static const String copyrightUrl = 'https://framidia.com/';

  // Layout dimensions
  static const double maxContentWidth = 1200.0;
  static const double headerHeight = 70.0;
  static const double footerHeight = 200.0;
  static const double sidebarWidth = 280.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusRound = 50.0;

  // Product card dimensions
  static const double productCardWidth = 280.0;
  static const double productCardImageHeight = 200.0;
  static const double productCardMinHeight = 320.0;

  // Grid settings
  static const int gridColumnsDesktop = 4;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsMobile = 2;
  static const double gridSpacing = 20.0;

  // Pagination
  static const int itemsPerPage = 20;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  // Navigation items
  static const List<Map<String, String>> navigationItems = [
    {'title': 'Assets', 'route': '/assets'},
    {'title': 'Export', 'route': '/export'},
    {'title': 'Import', 'route': '/import'},
    {'title': 'Settings', 'route': '/settings'},
  ];

  // Footer links
  static const List<Map<String, String>> footerPolicyLinks = [
    {'title': 'FAQ', 'route': '/faq'},
    {'title': 'Terms of Service', 'route': '/terms'},
    {'title': 'Privacy Policy', 'route': '/privacy'},
    {'title': 'DMCA', 'route': '/dmca'},
  ];

  // Membership pricing
  static const List<Map<String, dynamic>> membershipPlans = [
    {
      'name': 'Monthly',
      'price': 10.0,
      'period': 'month',
      'features': ['Access to all products', 'Monthly updates', 'Basic support'],
    },
    {
      'name': 'Yearly',
      'price': 40.0,
      'period': 'year',
      'features': ['Access to all products', 'Yearly updates', 'Priority support', 'Save 67%'],
      'popular': true,
    },
    {
      'name': 'Lifetime',
      'price': 99.0,
      'period': 'lifetime',
      'features': ['Access to all products', 'Lifetime updates', 'Premium support', 'Best value'],
    },
  ];

  // Sort options (legacy, kept for compatibility)
  static const List<Map<String, String>> sortOptions = [
    {'value': 'latest', 'label': 'Sort by latest'},
    {'value': 'title', 'label': 'Sort by title'},
    {'value': 'downloads', 'label': 'Sort by downloads'},
    {'value': 'size_asc', 'label': 'Sort by size: small to large'},
    {'value': 'size_desc', 'label': 'Sort by size: large to small'},
  ];

  // Asset-specific sort options
  static const List<Map<String, String>> assetSortOptions = [
    {'value': 'latest', 'label': 'Sort by latest'},
    {'value': 'title', 'label': 'Sort by title'},
    {'value': 'downloads', 'label': 'Sort by downloads'},
    {'value': 'size_asc', 'label': 'Sort by size: small to large'},
    {'value': 'size_desc', 'label': 'Sort by size: large to small'},
  ];
}
