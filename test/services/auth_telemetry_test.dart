import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/auth_telemetry.dart';

void main() {
  group('AuthTelemetry', () {
    test('normalizes metadata provider', () {
      expect(
        AuthTelemetry.metadataProvider({'provider': ' Google '}),
        equals('google'),
      );
      expect(AuthTelemetry.metadataProvider({'provider': ''}), isNull);
      expect(AuthTelemetry.metadataProvider(null), isNull);
    });

    test('builds sorted linked providers from metadata and identities', () {
      final providers = AuthTelemetry.linkedProviders(
        metadataProvider: 'apple',
        metadataProvidersRaw: ['google', 'apple'],
        identityProviders: const ['email', 'google'],
      );

      expect(providers, equals(['apple', 'email', 'google']));
      expect(
        AuthTelemetry.linkedProvidersValue(providers),
        'apple|email|google',
      );
    });

    test('returns none when linked providers are empty', () {
      final providers = AuthTelemetry.linkedProviders(
        metadataProvider: null,
        metadataProvidersRaw: null,
        identityProviders: null,
      );
      expect(providers, isEmpty);
      expect(AuthTelemetry.linkedProvidersValue(providers), 'none');
    });

    test('uses session provider for current session source', () {
      final source = AuthTelemetry.currentSessionSource(
        hasSession: true,
        sessionProvider: 'google',
        fallbackProvider: 'apple',
      );
      expect(source, 'google');
    });

    test('uses fallback provider for current session source when needed', () {
      final source = AuthTelemetry.currentSessionSource(
        hasSession: true,
        sessionProvider: null,
        fallbackProvider: 'apple',
      );
      expect(source, 'apple');
    });

    test('returns none for current session source when signed out', () {
      final source = AuthTelemetry.currentSessionSource(
        hasSession: false,
        sessionProvider: 'google',
        fallbackProvider: 'apple',
      );
      expect(source, 'none');
    });

    test('selects most recent identity provider by lastSignInAt', () {
      final provider = AuthTelemetry.mostRecentIdentityProvider([
        {'provider': 'apple', 'lastSignInAt': '2026-01-01T00:00:00Z'},
        {'provider': 'google', 'lastSignInAt': '2026-03-01T00:00:00Z'},
      ], fallbackProvider: 'apple');

      expect(provider, 'google');
    });

    test('truncates user ID for logs', () {
      expect(AuthTelemetry.truncatedUserId('1234567890'), '12345678...');
      expect(AuthTelemetry.truncatedUserId('1234'), '1234');
      expect(AuthTelemetry.truncatedUserId(null), isNull);
    });

    test('builds stable analytics params for auth state event', () {
      final params = AuthTelemetry.authStateAnalyticsParams(
        event: 'signedIn',
        hasSession: true,
        lastSignInProvider: 'google',
        currentSessionSource: 'google',
        linkedProviderCount: 2,
      );

      expect(params['event'], 'signedIn');
      expect(params['has_session'], isA<bool>());
      expect(params['last_sign_in_provider'], 'google');
      expect(params['current_session_source'], 'google');
      expect(params['linked_provider_count'], 2);
    });
  });
}
