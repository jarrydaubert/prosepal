import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateNotifier and StateProvider are in legacy.dart for Riverpod 2.x
// These are still fully supported; "legacy" just means non-code-gen API
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/interfaces.dart';
import '../models/models.dart';
import '../services/services.dart';

// ============================================================
// Provider Architecture Notes
// ============================================================
//
// This file follows Riverpod 2.x best practices:
// - Services as singletons via Provider (testable via overrides)
// - Reactive state via StateNotifierProvider (CustomerInfo)
// - Derived state via Provider (isProProvider, remainingGenerationsProvider)
// - Form state via StateProvider (simple, no validation logic)
//
// StateNotifier/StateProvider from legacy.dart are fully supported in
// Riverpod 2.x. The "legacy" designation refers to the non-code-gen API,
// not deprecated functionality.
//
// For testing, override auth providers and sharedPreferencesProvider.
// See test/mocks/ for examples.
//

// ============================================================
// Auth Provider Dependencies (for dependency injection)
// ============================================================

/// Apple auth provider - can be overridden in tests
final appleAuthProvider = Provider<IAppleAuthProvider>((ref) {
  return AppleAuthProvider();
});

/// Google auth provider - can be overridden in tests
final googleAuthProvider = Provider<IGoogleAuthProvider>((ref) {
  return GoogleAuthProvider();
});

/// Supabase auth provider - can be overridden in tests
final supabaseAuthProvider = Provider<ISupabaseAuthProvider>((ref) {
  return SupabaseAuthProvider();
});

// ============================================================
// Service Providers (singletons, testable via overrides)
// ============================================================

/// Auth service provider - uses injected dependencies
final authServiceProvider = Provider<IAuthService>((ref) {
  return AuthService(
    supabaseAuth: ref.watch(supabaseAuthProvider),
    appleAuth: ref.watch(appleAuthProvider),
    googleAuth: ref.watch(googleAuthProvider),
  );
});

/// Auth throttle service - rate limiting for auth attempts
final authThrottleServiceProvider = Provider<AuthThrottleService>((ref) {
  return AuthThrottleService();
});

/// Auth state stream - widgets can watch this to react to sign in/out
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Whether user is currently logged in - reacts to auth state changes
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session != null) ?? false;
});

/// SharedPreferences provider - MUST be initialized in main.dart before runApp
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final prefs = await SharedPreferences.getInstance();
///   runApp(ProviderScope(
///     overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///     child: MyApp(),
///   ));
/// }
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider not initialized. '
    'Override it in main.dart before runApp(). '
    'See provider documentation for example.',
  );
});

/// Device fingerprint service for server-side free tier tracking
final deviceFingerprintServiceProvider = Provider<DeviceFingerprintService>((
  ref,
) {
  return DeviceFingerprintService();
});

/// Rate limiting service to prevent API abuse
final rateLimitServiceProvider = Provider<RateLimitService>((ref) {
  final deviceFingerprint = ref.watch(deviceFingerprintServiceProvider);
  return RateLimitService(deviceFingerprint);
});

/// Usage tracking service
final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final deviceFingerprint = ref.watch(deviceFingerprintServiceProvider);
  final rateLimit = ref.watch(rateLimitServiceProvider);
  return UsageService(prefs, deviceFingerprint, rateLimit);
});

/// Generation history service
final historyServiceProvider = Provider<HistoryService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryService(prefs);
});

/// AI generation service (Firebase AI - no API key needed in client code)
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// Subscription/payment service
final subscriptionServiceProvider = Provider<ISubscriptionService>((ref) {
  return SubscriptionService();
});

/// App review prompting service
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReviewService(prefs);
});

/// Biometric authentication service
final biometricServiceProvider = Provider<IBiometricService>((ref) {
  return BiometricService();
});

/// Re-authentication service for sensitive operations
final reauthServiceProvider = Provider<ReauthService>((ref) {
  final biometricService = ref.watch(biometricServiceProvider);
  return ReauthService(
    biometricService: biometricService,
    supabaseAuth: Supabase.instance.client.auth,
  );
});

// ============================================================
// RevenueCat CustomerInfo (Reactive via StateNotifier + Listener)
// ============================================================

/// Notifier that holds the latest CustomerInfo and listens for updates
class CustomerInfoNotifier extends StateNotifier<CustomerInfo?> {
  final ISubscriptionService _subscriptionService;

  CustomerInfoNotifier(this._subscriptionService) : super(null) {
    // Add listener for live updates
    _subscriptionService.addCustomerInfoListener(_updateCustomerInfo);

    // Initial fetch
    _subscriptionService.getCustomerInfo().then((info) {
      if (info != null) _updateCustomerInfo(info);
    });
  }

  void _updateCustomerInfo(CustomerInfo info) {
    final hasPro = info.entitlements.active.containsKey('pro');
    final activeEntitlements = info.entitlements.active.keys.toList();
    Log.info('Pro status updated', {
      'hasPro': hasPro,
      'activeEntitlements': activeEntitlements,
    });
    state = info;
  }

  @override
  void dispose() {
    _subscriptionService.removeCustomerInfoListener(_updateCustomerInfo);
    super.dispose();
  }
}

/// Provider for the live CustomerInfo (null while loading/initial)
final customerInfoProvider =
    StateNotifierProvider<CustomerInfoNotifier, CustomerInfo?>((ref) {
      final subscriptionService = ref.watch(subscriptionServiceProvider);
      return CustomerInfoNotifier(subscriptionService);
    });

/// Reactive pro subscription status (live from RevenueCat)
/// False while loading or if no pro entitlement
final isProProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo?.entitlements.active.containsKey('pro') ?? false;
});

/// Async manual check with error handling
/// Prefer `isProProvider` for reactive UI - this is for one-off checks.
/// Returns false on error (safe default for monetization).
final checkProStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    return await subscriptionService.isPro();
  } catch (e) {
    Log.warning('checkProStatusProvider failed, returning false', {
      'error': '$e',
    });
    return false;
  }
});

// ============================================================
// Derived Usage State
// ============================================================

/// Total messages generated (lifetime)
final totalUsageProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  return usageService.getTotalCount();
});

/// Remaining generations (considers live pro status)
final remainingGenerationsProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  final isPro = ref.watch(isProProvider);

  if (isPro) {
    return usageService.getRemainingProMonthly();
  }
  return usageService.getRemainingFree();
});

// ============================================================
// Generation Form State
// ============================================================
// Simple StateProvider for form fields. Consider consolidating into
// a single NotifierProvider<GenerationFormState> if validation logic
// is needed (see BACKLOG.md).

final selectedOccasionProvider = StateProvider<Occasion?>((ref) => null);

final selectedRelationshipProvider = StateProvider<Relationship?>(
  (ref) => null,
);

final selectedToneProvider = StateProvider<Tone?>((ref) => null);

final selectedLengthProvider = StateProvider<MessageLength>(
  (ref) => MessageLength.standard,
);

final recipientNameProvider = StateProvider<String>((ref) => '');

final personalDetailsProvider = StateProvider<String>((ref) => '');

// ============================================================
// Generation Results State
// ============================================================
// Transient state for current generation. Could add autoDispose
// if memory optimization is needed (see BACKLOG.md).

final generationResultProvider = StateProvider<GenerationResult?>(
  (ref) => null,
);

final isGeneratingProvider = StateProvider<bool>((ref) => false);

final generationErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================
// Form Reset Utility
// ============================================================

void resetGenerationForm(WidgetRef ref) {
  ref.read(selectedOccasionProvider.notifier).state = null;
  ref.read(selectedRelationshipProvider.notifier).state = null;
  ref.read(selectedToneProvider.notifier).state = null;
  ref.read(selectedLengthProvider.notifier).state = MessageLength.standard;
  ref.read(recipientNameProvider.notifier).state = '';
  ref.read(personalDetailsProvider.notifier).state = '';
  ref.read(generationResultProvider.notifier).state = null;
  ref.read(generationErrorProvider.notifier).state = null;
}
