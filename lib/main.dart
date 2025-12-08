import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'providers/asset_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/search_provider.dart';
import 'providers/ui_state_provider.dart';
import 'providers/upload_provider.dart';
import 'services/service_locator.dart';
import 'widgets/auth/login_dialog.dart';
import 'widgets/export/export_all_dialog.dart';
import 'widgets/export/export_progress_dialog.dart';
import 'widgets/export/export_complete_dialog.dart';
import 'models/export_progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize services
  await ServiceLocator.instance.initialize();

  runApp(const GvStorageApp());
}

/// Global function to handle export all data
/// Can be called from anywhere using the root navigator context
Future<void> handleExportAllData() async {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;

  try {
    // Show initial confirmation dialog
    final destinationPath = await showDialog<String>(
      context: context,
      builder: (context) => const ExportAllDialog(),
    );

    if (destinationPath == null) {
      // User cancelled
      return;
    }

    // Create cancellation token
    final cancellationToken = ExportCancellationToken();

    // Create progress stream
    final originalStream = services.export.exportAllDataWithProgress(
      destinationPath,
      cancellationToken,
    );

    // Convert to broadcast stream so multiple listeners can subscribe
    final streamController = StreamController<ExportProgress>.broadcast();

    ExportProgress? lastProgress;
    final completer = Completer<ExportProgress?>();

    // Listen to original stream and broadcast to multiple listeners
    originalStream.listen(
      (progress) {
        streamController.add(progress);
        lastProgress = progress;
        if (progress.isComplete) {
          completer.complete(progress);
        }
      },
      onError: (error) {
        streamController.addError(error);
        completer.completeError(error);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(lastProgress);
        }
        streamController.close();
      },
    );

    // Show progress dialog
    if (!context.mounted) return;

    // Show progress dialog (non-dismissible)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportProgressDialog(
        progressStream: streamController.stream,
        onCancel: () {
          cancellationToken.cancel();
        },
      ),
    );

    // Wait for completion or error
    final result = await completer.future;

    // Close progress dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show completion or error dialog
    if (context.mounted) {
      if (result != null && result.isComplete) {
        await showDialog(
          context: context,
          builder: (context) => ExportCompleteDialog(
            exportPath: destinationPath,
            totalAssets: result.totalAssets,
            totalFiles: result.totalFiles,
          ),
        );
      }
    }
  } on ExportCancelledException {
    // User cancelled, show message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export cancelled'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  } on ExportException catch (e) {
    // Export error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (e) {
    // Unexpected error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Main application widget
class GvStorageApp extends StatelessWidget {
  const GvStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
      ],
      child: const AuthenticatedApp(),
    );
  }
}

/// Authenticated app wrapper that shows login dialog on startup
class AuthenticatedApp extends StatefulWidget {
  const AuthenticatedApp({super.key});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  @override
  void initState() {
    super.initState();
    // Show login dialog after first frame when navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoginDialog();
    });
  }

  Future<void> _showLoginDialog() async {
    final authProvider = context.read<AuthProvider>();

    // Don't show dialog if already authenticated
    if (authProvider.isAuthenticated) {
      return;
    }

    // Wait for navigator to be ready
    await Future.delayed(const Duration(milliseconds: 100));

    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    // Show login dialog - can't be dismissed except by successful login
    await showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'GvStorage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    );
  }
}

