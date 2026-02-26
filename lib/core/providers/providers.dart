import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Required for StateProvider in Riverpod 3.x
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/services.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

// Usage service provider
final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UsageService(prefs);
});

// AI service provider
final aiServiceProvider = Provider<AiService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY not set');
  }
  return AiService(apiKey: apiKey);
});

// Subscription service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Pro status - updated by RevenueCat listener
final isProProvider = StateProvider<bool>((ref) => false);

// Check pro status from RevenueCat
final checkProStatusProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.isPro();
});

// Usage state
final totalUsageProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  return usageService.getTotalCount();
});

final remainingGenerationsProvider = Provider<int>((ref) {
  final usageService = ref.watch(usageServiceProvider);
  final isPro = ref.watch(isProProvider);

  if (isPro) {
    return usageService.getRemainingProMonthly();
  }
  return usageService.getRemainingFree(); // Lifetime limit for free users
});

// Generation state
final selectedOccasionProvider = StateProvider<Occasion?>((ref) => null);
final selectedRelationshipProvider = StateProvider<Relationship?>(
  (ref) => null,
);
final selectedToneProvider = StateProvider<Tone?>((ref) => null);
final recipientNameProvider = StateProvider<String>((ref) => '');
final personalDetailsProvider = StateProvider<String>((ref) => '');

// Generation results
final generationResultProvider = StateProvider<GenerationResult?>(
  (ref) => null,
);
final isGeneratingProvider = StateProvider<bool>((ref) => false);
final generationErrorProvider = StateProvider<String?>((ref) => null);

// Reset generation form
void resetGenerationForm(WidgetRef ref) {
  ref.read(selectedOccasionProvider.notifier).state = null;
  ref.read(selectedRelationshipProvider.notifier).state = null;
  ref.read(selectedToneProvider.notifier).state = null;
  ref.read(recipientNameProvider.notifier).state = '';
  ref.read(personalDetailsProvider.notifier).state = '';
  ref.read(generationResultProvider.notifier).state = null;
  ref.read(generationErrorProvider.notifier).state = null;
}
