import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'app_header.dart';
import 'app_footer.dart';

/// Main scaffold wrapper for all pages
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? sidebar;
  final bool showFooter;
  final String? currentRoute;
  final Function(String)? onNavigate;
  final VoidCallback? onUploadTap;
  final VoidCallback? onExportAllData;
  final ScrollController? scrollController;

  const AppScaffold({
    super.key,
    required this.body,
    this.sidebar,
    this.showFooter = true,
    this.currentRoute,
    this.onNavigate,
    this.onUploadTap,
    this.onExportAllData,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          AppHeader(
            currentRoute: currentRoute,
            onNavigate: onNavigate,
            onUploadTap: onUploadTap,
            onExportAllData: onExportAllData,
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  // Body with optional sidebar
                  _buildMainContent(),

                  // Footer
                  if (showFooter)
                    AppFooter(
                      onNavigate: onNavigate,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (sidebar != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar
                SizedBox(
                  width: AppConstants.sidebarWidth,
                  child: sidebar,
                ),
                const SizedBox(width: AppConstants.spacingLg),

                // Main content
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: body,
        ),
      ),
    );
  }
}
