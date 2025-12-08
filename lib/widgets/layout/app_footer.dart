import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Main application footer
class AppFooter extends StatelessWidget {
  final Function(String)? onNavigate;

  const AppFooter({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.footerBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXl,
        vertical: AppConstants.spacingXl,
      ),
      child: Column(
        children: [
          // Main footer content
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company info
                Expanded(flex: 2, child: _buildCompanyInfo()),
                const SizedBox(width: AppConstants.spacingXl),

                // Product categories
                Expanded(child: _buildProductCategories()),
                const SizedBox(width: AppConstants.spacingXl),

                // Contact / Trust badge
                Expanded(child: _buildTrustSection()),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingLg),
          const Divider(color: AppColors.textHint, height: 1),
          const SizedBox(height: AppConstants.spacingMd),

          // Copyright
          _buildCopyright(),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: AppColors.textOnPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'WPSHOP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          'Premium WordPress Themes, Plugins, and PHP Scripts at affordable prices. '
          'Get access to thousands of digital products with our membership plans.',
          style: AppTextStyles.footer.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildProductCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        ...AppConstants.navigationItems.take(4).map(
              (item) => _FooterLink(
                title: item['title']!,
                onTap: () => onNavigate?.call(item['route']!),
              ),
            ),
      ],
    );
  }

  Widget _buildTrustSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secure Shopping',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'SSL Secured',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Row(
          children: [
            const Icon(
              Icons.credit_card,
              color: AppColors.footerText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Safe Payments',
              style: AppTextStyles.footer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchUrl(),
        child: RichText(
          text: TextSpan(
            text: AppConstants.copyright,
            style: AppTextStyles.footer.copyWith(
              color: AppColors.footerText,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(AppConstants.copyrightUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${AppConstants.copyrightUrl}');
    }
  }
}

class _FooterLink extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const _FooterLink({
    required this.title,
    this.onTap,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            widget.title,
            style: AppTextStyles.footer.copyWith(
              color: _isHovered ? AppColors.textOnPrimary : AppColors.footerText,
              decoration: _isHovered ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }
}
