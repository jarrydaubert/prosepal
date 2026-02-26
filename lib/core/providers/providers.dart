import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Required for legacy StateProvider (your existing form providers)
import 'package:purchases_flutter/purchases_flutter.dart'; // Required for CustomerInfo
import 'package:shared_preferences/shared_preferences.dart';

import '../interfaces/interfaces.dart';
import '../models/models.dart';
import '../services/services.dart';

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

/// SharedPreferences provider - must be initialized in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

/// Usage tracking service
final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UsageService(prefs);
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
    debugPrint('CustomerInfoNotifier: updated, hasPro=$hasPro');
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

/// Async manual check (kept for backward compatibility if any code uses it)
final checkProStatusProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.isPro();
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
// Generation Form State (Legacy StateProvider - kept for compatibility)
// ============================================================

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
// Generation Results State (Legacy StateProvider - kept for compatibility)
// ============================================================

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
