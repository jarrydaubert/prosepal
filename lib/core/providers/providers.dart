import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateNotifier and StateProvider are in legacy.dart for Riverpod 2.x
// These are still fully supported; "legacy" just means non-code-gen API
// ignore: implementation_imports
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/preference_keys.dart';
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
// Init Status Provider (for startup loading states)
// ============================================================

/// Tracks initialization status of services for UI loading states.
///
/// UI components can watch this to show loading indicators while
/// services are initializing.
class InitStatus {
  const InitStatus({
    this.supabaseReady = false,
    this.revenueCatReady = false,
    this.remoteConfigReady = false,
    this.timedOut = false,
    this.error,
    this.forceUpdateRequired = false,
    this.forceUpdateStoreUrl,
  });

  final bool supabaseReady;
  final bool revenueCatReady;
  final bool remoteConfigReady;
  final bool timedOut;
  final String? error;
  final bool forceUpdateRequired;
  final String? forceUpdateStoreUrl;

  /// Convenience getters
  bool get isSupabaseReady => supabaseReady;
  bool get isRevenueCatReady => revenueCatReady;
  bool get isRemoteConfigReady => remoteConfigReady;
  bool get isTimedOut => timedOut;
  bool get hasError => error != null;

  /// Critical services ready (Supabase is required for auth/data)
  bool get criticalReady => supabaseReady;

  /// All services ready
  bool get allReady => supabaseReady && revenueCatReady;

  InitStatus copyWith({
    bool? supabaseReady,
    bool? revenueCatReady,
    bool? remoteConfigReady,
    bool? timedOut,
    String? error,
    bool? forceUpdateRequired,
    String? forceUpdateStoreUrl,
  }) {
    return InitStatus(
      supabaseReady: supabaseReady ?? this.supabaseReady,
      revenueCatReady: revenueCatReady ?? this.revenueCatReady,
      remoteConfigReady: remoteConfigReady ?? this.remoteConfigReady,
      timedOut: timedOut ?? this.timedOut,
      error: error ?? this.error,
      forceUpdateRequired: forceUpdateRequired ?? this.forceUpdateRequired,
      forceUpdateStoreUrl: forceUpdateStoreUrl ?? this.forceUpdateStoreUrl,
    );
  }
}

/// Notifier for initialization status.
///
/// Updated by main.dart as services initialize.
class InitStatusNotifier extends StateNotifier<InitStatus> {
  InitStatusNotifier() : super(const InitStatus());

  void markSupabaseReady() {
    state = state.copyWith(supabaseReady: true);
  }

  void markRevenueCatReady() {
    state = state.copyWith(revenueCatReady: true);
  }

  void markRemoteConfigReady() {
    state = state.copyWith(remoteConfigReady: true);
  }

  void markTimedOut() {
    state = state.copyWith(timedOut: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void setForceUpdate(String storeUrl) {
    state = state.copyWith(
      forceUpdateRequired: true,
      forceUpdateStoreUrl: storeUrl,
    );
  }

  void reset() {
    state = const InitStatus();
  }
}

/// Provider for initialization status.
///
/// Watch this in UI to show loading states during startup.
final initStatusProvider =
    StateNotifierProvider<InitStatusNotifier, InitStatus>((ref) {
      return InitStatusNotifier();
    });

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

/// Generation history service (uses secure storage internally)
final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

/// Data export service for GDPR/CCPA data portability
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService(
    usageService: ref.watch(usageServiceProvider),
    historyService: ref.watch(historyServiceProvider),
  );
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
final reauthServiceProvider = Provider<ReauthService?>((ref) {
  // Return null if Supabase isn't initialized yet
  try {
    Supabase.instance.client;
  } catch (_) {
    return null;
  }
  final biometricService = ref.watch(biometricServiceProvider);
  return ReauthService(
    biometricService: biometricService,
    supabaseAuth: Supabase.instance.client.auth,
  );
});

// ============================================================
// RevenueCat CustomerInfo (Reactive via StateNotifier + Listener)
// ============================================================

/// Key for caching pro status in SharedPreferences
const _proStatusCacheKey = 'cached_pro_status';

/// Notifier that holds the latest CustomerInfo and listens for updates
class CustomerInfoNotifier extends StateNotifier<CustomerInfo?> {
  final ISubscriptionService _subscriptionService;
  final SharedPreferences _prefs;

  bool _hasReceivedListenerUpdate = false;

  CustomerInfoNotifier(this._subscriptionService, this._prefs) : super(null) {
    // Add listener for live updates (may fire immediately)
    _subscriptionService.addCustomerInfoListener(_onListenerUpdate);

    // Initial fetch - only use if listener hasn't already provided data
    _subscriptionService.getCustomerInfo().then((info) {
      if (info != null && !_hasReceivedListenerUpdate) {
        _updateCustomerInfo(info);
      }
    });
  }

  void _onListenerUpdate(CustomerInfo info) {
    _hasReceivedListenerUpdate = true;
    _updateCustomerInfo(info);
  }

  void _updateCustomerInfo(CustomerInfo info) {
    final hasPro = info.entitlements.active.containsKey('pro');
    final activeEntitlements = info.entitlements.active.keys.toList();
    Log.info('Pro status updated', {
      'hasPro': hasPro,
      'activeEntitlements': activeEntitlements,
    });
    state = info;

    // Cache pro status for offline fallback
    _prefs.setBool(_proStatusCacheKey, hasPro);
  }

  @override
  void dispose() {
    _subscriptionService.removeCustomerInfoListener(_onListenerUpdate);
    super.dispose();
  }
}

/// Provider for the live CustomerInfo (null while loading/initial)
final customerInfoProvider =
    StateNotifierProvider<CustomerInfoNotifier, CustomerInfo?>((ref) {
      final subscriptionService = ref.watch(subscriptionServiceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      return CustomerInfoNotifier(subscriptionService, prefs);
    });

/// Reactive pro subscription status (live from RevenueCat)
/// Uses cached value as fallback when offline or loading
final isProProvider = Provider<bool>((ref) {
  final customerInfo = ref.watch(customerInfoProvider);
  if (customerInfo != null) {
    return customerInfo.entitlements.active.containsKey('pro');
  }
  // Fallback to cached value when offline/loading
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_proStatusCacheKey) ?? false;
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
// Spelling Preference
// ============================================================

/// Spelling preference: 'us' or 'uk'
/// Used to customize AI output (Mom vs Mum, favorite vs favourite)
final spellingPreferenceProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString(PreferenceKeys.spellingPreference) ??
      PreferenceKeys.spellingPreferenceDefault;
});

/// Whether UK spelling is enabled
final isUkSpellingProvider = Provider<bool>((ref) {
  return ref.watch(spellingPreferenceProvider) == 'uk';
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
// Occasion Search State
// ============================================================
// Search query for filtering occasions on home screen.
// autoDispose so it resets when leaving home screen.

final occasionSearchProvider = StateProvider<String>((ref) => '');

/// Filtered occasions based on search query.
/// Matches against label (case-insensitive).
final filteredOccasionsProvider = Provider<List<Occasion>>((ref) {
  final query = ref.watch(occasionSearchProvider).toLowerCase().trim();
  if (query.isEmpty) return Occasion.values;
  return Occasion.values
      .where((o) => o.label.toLowerCase().contains(query))
      .toList();
});

// ============================================================
// Generation Form State
// ============================================================
// Form providers - selectedOccasion must NOT autoDispose as it's set before
// navigation and needs to survive the route transition. Other form fields
// autoDispose when GenerateScreen is disposed to prevent memory leaks.

final selectedOccasionProvider = StateProvider<Occasion?>((ref) => null);

final selectedRelationshipProvider = StateProvider.autoDispose<Relationship?>(
  (ref) => null,
);

final selectedToneProvider = StateProvider.autoDispose<Tone?>((ref) => null);

final selectedLengthProvider = StateProvider.autoDispose<MessageLength>(
  (ref) => MessageLength.standard,
);

final recipientNameProvider = StateProvider.autoDispose<String>((ref) => '');

final personalDetailsProvider = StateProvider.autoDispose<String>((ref) => '');

// ============================================================
// Generation Results State
// ============================================================
// generationResultProvider must NOT autoDispose - it's set before navigation
// and needs to survive the route transition to results screen.

final generationResultProvider = StateProvider<GenerationResult?>(
  (ref) => null,
);

final isGeneratingProvider = StateProvider.autoDispose<bool>((ref) => false);

final generationErrorProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Pending paywall source - set this before navigating to home to auto-show paywall.
/// Home screen checks this on build and shows paywall if non-null, then clears it.
final pendingPaywallSourceProvider = StateProvider<String?>((ref) => null);

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
