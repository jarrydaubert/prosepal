import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// App review prompting service
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReviewService(prefs);
});

// ============================================================
// Pro Status
// ============================================================

/// Pro subscription status - updated by RevenueCat listener
final isProProvider = StateProvider<bool>((ref) => false);

/// Async check of pro status from RevenueCat
final checkProStatusProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.isPro();
});

// ============================================================
// Derived Usage State
// ============================================================

/// Total messages generated (lifetime)
final totalUsageProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  return usageService.getTotalCount();
});

/// Remaining generations (considers pro status)
final remainingGenerationsProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  final isPro = ref.watch(isProProvider);

  if (isPro) {
    return usageService.getRemainingProMonthly();
  }
  return usageService.getRemainingFree();
});

// ============================================================
// Generation Form State (Legacy StateProvider - for compatibility)
// ============================================================
// Note: These use legacy StateProvider for backward compatibility with
// existing screens that use `.notifier.state = value` pattern.
// Future migration: Replace with Notifier pattern when updating screens.

/// Selected occasion for generation
final selectedOccasionProvider = StateProvider<Occasion?>((ref) => null);

/// Selected relationship for generation
final selectedRelationshipProvider = StateProvider<Relationship?>((ref) => null);

/// Selected tone for generation
final selectedToneProvider = StateProvider<Tone?>((ref) => null);

/// Selected message length
final selectedLengthProvider = StateProvider<MessageLength>(
  (ref) => MessageLength.standard,
);

/// Recipient name (optional)
final recipientNameProvider = StateProvider<String>((ref) => '');

/// Personal details (optional)
final personalDetailsProvider = StateProvider<String>((ref) => '');

// ============================================================
// Generation Results State (Legacy StateProvider - for compatibility)
// ============================================================

/// Result of AI generation
final generationResultProvider = StateProvider<GenerationResult?>((ref) => null);

/// Whether generation is in progress
final isGeneratingProvider = StateProvider<bool>((ref) => false);

/// Error message from generation
final generationErrorProvider = StateProvider<String?>((ref) => null);

// ============================================================
// Form Reset Utility
// ============================================================

/// Reset all generation form state
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
