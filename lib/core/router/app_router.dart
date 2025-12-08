import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/pages.dart';

/// Global navigator key for showing dialogs from anywhere
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/assets',
      builder: (context, state) => const AssetListingPage(),
    ),
    GoRoute(
      path: '/category/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug'];
        return AssetListingPage(categorySlug: slug);
      },
    ),
    GoRoute(
      path: '/asset/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return AssetDetailPage(slug: slug);
      },
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const UploadAssetPage(),
    ),
  ],
);

