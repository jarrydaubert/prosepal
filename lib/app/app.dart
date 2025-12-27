import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/providers.dart';
import '../shared/theme/app_theme.dart';
import 'router.dart';

class ProsepalApp extends ConsumerStatefulWidget {
  const ProsepalApp({super.key});

  @override
  ConsumerState<ProsepalApp> createState() => _ProsepalAppState();
}

class _ProsepalAppState extends ConsumerState<ProsepalApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen for auth state changes (magic link, OAuth callback, etc.)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Link RevenueCat to user for purchase restoration
        await ref.read(subscriptionServiceProvider).identifyUser(session.user.id);
        // Navigate to home
        appRouter.go('/home');
      } else if (event == AuthChangeEvent.signedOut) {
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
    );
  }
}
