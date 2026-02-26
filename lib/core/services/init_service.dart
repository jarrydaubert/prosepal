/// Tracks initialization status of critical services.
///
/// Used to show error screen if critical services fail to initialize.
/// Non-critical services (RevenueCat, ScreenSecure) can fail without blocking.
class InitService {
  InitService._();

  static final instance = InitService._();

  // Initialization status
  bool _firebaseInitialized = false;
  bool _supabaseInitialized = false;
  bool _revenueCatInitialized = false;

  // Error messages
  String? _firebaseError;
  String? _supabaseError;
  String? _revenueCatError;

  /// Mark Firebase as initialized
  void firebaseReady() => _firebaseInitialized = true;

  /// Mark Firebase as failed
  void firebaseFailed(String error) => _firebaseError = error;

  /// Mark Supabase as initialized
  void supabaseReady() => _supabaseInitialized = true;

  /// Mark Supabase as failed
  void supabaseFailed(String error) => _supabaseError = error;

  /// Mark RevenueCat as initialized
  void revenueCatReady() => _revenueCatInitialized = true;

  /// Mark RevenueCat as failed
  void revenueCatFailed(String error) => _revenueCatError = error;

  /// Check if all critical services are ready
  ///
  /// Critical services: Firebase (for crash reporting), Supabase (for auth/data)
  /// Non-critical: RevenueCat (gracefully degraded - users just can't subscribe)
  bool get isCriticalReady => _firebaseInitialized && _supabaseInitialized;

  /// Check if Firebase is ready
  bool get isFirebaseReady => _firebaseInitialized;

  /// Check if Supabase is ready
  bool get isSupabaseReady => _supabaseInitialized;

  /// Check if RevenueCat is ready
  bool get isRevenueCatReady => _revenueCatInitialized;

  /// Get error message if critical services failed
  String? get criticalError {
    if (!_firebaseInitialized && _firebaseError != null) {
      return 'Firebase: $_firebaseError';
    }
    if (!_supabaseInitialized && _supabaseError != null) {
      return 'Supabase: $_supabaseError';
    }
    return null;
  }

  /// Get all errors (for diagnostics)
  Map<String, String?> get allErrors => {
    'firebase': _firebaseError,
    'supabase': _supabaseError,
    'revenueCat': _revenueCatError,
  };

  /// Check if any service failed (for showing warning)
  bool get hasAnyError =>
      _firebaseError != null ||
      _supabaseError != null ||
      _revenueCatError != null;

  /// Reset state for retry logic (also used in tests)
  void reset() {
    _firebaseInitialized = false;
    _supabaseInitialized = false;
    _revenueCatInitialized = false;
    _firebaseError = null;
    _supabaseError = null;
    _revenueCatError = null;
  }
}
