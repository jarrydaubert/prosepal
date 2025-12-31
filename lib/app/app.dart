import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/providers.dart';
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
    setState(() {
      // Flutter 3.13+ added 'hidden' for brief non-visible transitions
      _isInBackground =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
    });
  }

  void _setupAuthListener() {
    // Listen for auth state changes (magic link, OAuth callback, etc.)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Link RevenueCat to user for purchase restoration
        await ref
            .read(subscriptionServiceProvider)
            .identifyUser(session.user.id);
        // Sync usage from server (restores usage after reinstall)
        await ref.read(usageServiceProvider).syncFromServer();
        // Navigate to home
        appRouter.go('/home');
      } else if (event == AuthChangeEvent.signedOut) {
        // Clear sync marker so next user gets fresh sync
        await ref.read(usageServiceProvider).clearSyncMarker();
        appRouter.go('/auth');
      }
    });
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
