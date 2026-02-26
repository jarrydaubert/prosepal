import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/init_service.dart';

void main() {
  group('InitService', () {
    late InitService init;

    setUp(() {
      init = InitService.instance;
      init.reset();
    });

    group('Critical Service Tracking', () {
      test('isCriticalReady is false initially', () {
        expect(init.isCriticalReady, isFalse);
      });

      test('isCriticalReady requires both Firebase and Supabase', () {
        init.firebaseReady();
        expect(init.isCriticalReady, isFalse);

        init.supabaseReady();
        expect(init.isCriticalReady, isTrue);
      });

      test('isCriticalReady is false if only Supabase is ready', () {
        init.supabaseReady();
        expect(init.isCriticalReady, isFalse);
      });

      test('RevenueCat is not required for critical readiness', () {
        init.firebaseReady();
        init.supabaseReady();
        // RevenueCat not initialized
        expect(init.isCriticalReady, isTrue);
      });
    });

    group('Error Tracking', () {
      test('criticalError returns Firebase error first', () {
        init.firebaseFailed('Network error');
        expect(init.criticalError, contains('Firebase'));
        expect(init.criticalError, contains('Network error'));
      });

      test('criticalError returns Supabase error if Firebase ok', () {
        init.firebaseReady();
        init.supabaseFailed('Connection refused');
        expect(init.criticalError, contains('Supabase'));
        expect(init.criticalError, contains('Connection refused'));
      });

      test('criticalError returns null if all critical services ready', () {
        init.firebaseReady();
        init.supabaseReady();
        expect(init.criticalError, isNull);
      });

      test('hasAnyError tracks non-critical errors too', () {
        init.firebaseReady();
        init.supabaseReady();
        expect(init.hasAnyError, isFalse);

        init.revenueCatFailed('API error');
        expect(init.hasAnyError, isTrue);
        expect(init.isCriticalReady, isTrue); // Still ready
      });

      test('allErrors returns all error messages', () {
        init.firebaseFailed('Firebase error');
        init.supabaseFailed('Supabase error');
        init.revenueCatFailed('RevenueCat error');

        final errors = init.allErrors;
        expect(errors['firebase'], 'Firebase error');
        expect(errors['supabase'], 'Supabase error');
        expect(errors['revenueCat'], 'RevenueCat error');
      });
    });

    group('Reset', () {
      test('reset clears all state', () {
        init.firebaseReady();
        init.supabaseReady();
        init.revenueCatReady();
        init.firebaseFailed('error');

        init.reset();

        expect(init.isFirebaseReady, isFalse);
        expect(init.isSupabaseReady, isFalse);
        expect(init.isRevenueCatReady, isFalse);
        expect(init.criticalError, isNull);
      });
    });

    group('Individual Service Status', () {
      test('isFirebaseReady tracks Firebase status', () {
        expect(init.isFirebaseReady, isFalse);
        init.firebaseReady();
        expect(init.isFirebaseReady, isTrue);
      });

      test('isSupabaseReady tracks Supabase status', () {
        expect(init.isSupabaseReady, isFalse);
        init.supabaseReady();
        expect(init.isSupabaseReady, isTrue);
      });

      test('isRevenueCatReady tracks RevenueCat status', () {
        expect(init.isRevenueCatReady, isFalse);
        init.revenueCatReady();
        expect(init.isRevenueCatReady, isTrue);
      });
    });
  });
}
