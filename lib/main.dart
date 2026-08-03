import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'pages/print_dialog_page.dart';
import 'pages/pdf_print_view.dart';
import 'pages/image_print_view.dart';
import 'pages/passport_print_view.dart';
import 'pages/radar_discovery_screen.dart';
import 'pages/settings_page.dart';
import 'pages/home_page.dart';
import 'pages/quick_send_view.dart';
import 'pages/connect_method_page.dart';
import 'pages/remote_connect_page.dart';
import 'pages/history_page.dart';
import 'pages/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';
import 'pages/tracking_page.dart';
import 'pages/ai_bg_remover_page.dart';
import 'pages/dashboard_page.dart';
import 'package:digitol_admin_app/pages/file_preview_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FlutterError: ${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 Unhandled error: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: DigitolAdminApp()));
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/connect-method',
        builder: (context, state) => const ConnectMethodPage(),
      ),
      GoRoute(
        path: '/remote-connect',
        builder: (context, state) => const RemoteConnectPage(),
      ),
      GoRoute(
        path: '/radar',
        builder: (context, state) => const RadarDiscoveryScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/file-preview',
        builder: (context, state) {
          final job = state.extra as Map<String, dynamic>;
          return FilePreviewPage(job: job);
        },
      ),
      GoRoute(
        path: '/print-dialog',
        builder: (context, state) {
          final files = state.extra as List<PlatformFile>? ?? [];
          final filePaths = files.map((f) => f.path ?? '').where((p) => p.isNotEmpty).toList();
          return PrintDialogPage(filePaths: filePaths);
        },
      ),
      GoRoute(
        path: '/print/pdf',
        builder: (context, state) {
          final files = state.extra as List<PlatformFile>? ?? [];
          final file = files.isNotEmpty ? files.first : null;
          return PdfPrintView(file: file);
        },
      ),
      GoRoute(
        path: '/print/image',
        builder: (context, state) {
          final files = state.extra as List<PlatformFile>? ?? [];
          return ImagePrintView(files: files);
        },
      ),
      GoRoute(
        path: '/print/passport',
        builder: (context, state) {
          final files = state.extra as List<PlatformFile>? ?? [];
          final file = files.isNotEmpty ? files.first : null;
          return PassportPrintView(file: file);
        },
      ),
      GoRoute(
        path: '/print/quick_send',
        builder: (context, state) {
          final files = state.extra as List<PlatformFile>? ?? [];
          return QuickSendView(files: files);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return TrackingPage(
              jobId: extra['jobId'] as String? ?? '', 
              type: extra['type'] as String?
            );
          } else if (extra is String) {
            return TrackingPage(jobId: extra);
          }
          return const TrackingPage(jobId: '');
        },
      ),
      GoRoute(
        path: '/ai_bg_remover',
        builder: (context, state) => const AIBgRemoverPage(),
      ),
    ],
  );
});

class DigitolAdminApp extends ConsumerWidget {
  const DigitolAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'Digitol Admin App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
