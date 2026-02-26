import 'package:flutter_test/flutter_test.dart';
import 'package:prosepal/core/services/supabase_auth_provider.dart';

void main() {
  group('SupabaseAuthProvider initialization guards', () {
    late SupabaseAuthProvider provider;

    setUp(() {
      provider = SupabaseAuthProvider();
    });

    test('currentUser is null when Supabase is not initialized', () {
      expect(() => provider.currentUser, returnsNormally);
      expect(provider.currentUser, isNull);
    });

    test('currentSession is null when Supabase is not initialized', () {
      expect(() => provider.currentSession, returnsNormally);
      expect(provider.currentSession, isNull);
    });

    test(
      'auth state stream is empty when Supabase is not initialized',
      () async {
        expect(() => provider.onAuthStateChange, returnsNormally);
        expect(await provider.onAuthStateChange.isEmpty, isTrue);
      },
    );
  });
}
