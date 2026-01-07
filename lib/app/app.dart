import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/providers.dart';
import '../core/services/log_service.dart';
import '../shared/theme/app_colors.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

class ProsepalApp extends ConsumerStatefulWidget {
  const ProsepalApp({super.key});

  @override
  ConsumerState<ProsepalApp> createState() => _ProsepalAppState();
}

class _ProsepalAppState extends ConsumerState<ProsepalApp>
    with WidgetsBindingObserver {
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasInBackground = _isInBackground;
    setState(() {
      // Flutter 3.13+ added 'hidden' for brief non-visible transitions
      _isInBackground =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    });

    // Log lifecycle transitions
    if (_isInBackground && !wasInBackground) {
      Log.info('App backgrounded');
    } else if (!_isInBackground && wasInBackground) {
      Log.info('App resumed');
    }
  }

  void _setupAuthListener() {
    // Skip if Supabase isn't initialized (e.g., integration tests with mocks)
    try {
      final supabase = Supabase.instance;
      if (!supabase.isInitialized) return;

      // Listen for auth state changes (magic link, OAuth callback, etc.)
      supabase.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          // Link RevenueCat to user for purchase restoration
          await ref
              .read(subscriptionServiceProvider)
              .identifyUser(session.user.id);
          // Sync usage from server (restores usage after reinstall)
          await ref.read(usageServiceProvider).syncFromServer();
          // Note: Navigation is handled by AuthScreen._navigateAfterAuth()
          // This listener handles deep link / magic link callbacks when app is backgrounded
          final currentPath =
              appRouter.routerDelegate.currentConfiguration.fullPath;
          if (!currentPath.startsWith('/auth')) {
            appRouter.go('/home');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          // Clear sync marker so next user gets fresh sync
          await ref.read(usageServiceProvider).clearSyncMarker();
          // Go to home - anonymous users can still use free token
          appRouter.go('/home');
        }
      });
    } catch (_) {
      // Supabase not initialized - skip auth listener (integration tests with mocks)
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prosepal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Privacy screen when app is backgrounded
            if (_isInBackground)
              ColoredBox(
                color: AppColors.background,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
