/// Barrel file for service interfaces.
///
/// Provides a single import for all authentication and service abstractions:
/// ```dart
/// import 'package:prosepal/core/interfaces/interfaces.dart';
/// ```
///
/// ## Exported Interfaces
/// - [IAppleAuthProvider] - Apple Sign-In native SDK operations
/// - [IAuthService] - Core authentication service contract
/// - [IBiometricService] - Biometric authentication (Face ID, Touch ID)
/// - [IGoogleAuthProvider] - Google Sign-In native SDK operations
/// - [ISubscriptionService] - RevenueCat subscription management
/// - [ISupabaseAuthProvider] - Supabase-specific auth operations
///
/// All interfaces support dependency injection and mocking for testing.
library;

// Exports sorted alphabetically
export 'apple_auth_provider.dart';
export 'auth_interface.dart';
export 'biometric_interface.dart';
export 'google_auth_provider.dart';
export 'subscription_interface.dart';
export 'supabase_auth_provider.dart';
