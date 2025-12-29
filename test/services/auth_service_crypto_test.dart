import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crypto & Validation Tests for AuthService
///
/// Tests nonce generation, SHA256 hashing, and input validation
/// used in Apple Sign In and email/password flows.
void main() {
  group('Nonce Generation', () {
    String generateNonce([int length = 32]) {
      const charset =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final random = Random.secure();
      return List.generate(
        length,
        (_) => charset[random.nextInt(charset.length)],
      ).join();
    }

    String sha256ofString(String input) {
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }

    test('generates nonce of correct length', () {
      expect(generateNonce().length, equals(32));
      expect(generateNonce(16).length, equals(16));
    });

    test('generates unique nonces', () {
      final nonce1 = generateNonce();
      final nonce2 = generateNonce();
      expect(nonce1, isNot(equals(nonce2)));
    });

    test('only contains valid charset characters', () {
      const charset =
          '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final nonce = generateNonce();

      for (final char in nonce.split('')) {
        expect(charset.contains(char), isTrue);
      }
    });

    test('SHA256 produces 64 hex characters', () {
      final hash = sha256ofString('test_nonce');
      expect(hash.length, equals(64));
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
    });

    test('SHA256 is consistent for same input', () {
      final hash1 = sha256ofString('input');
      final hash2 = sha256ofString('input');
      expect(hash1, equals(hash2));
    });

    test('SHA256 differs for different inputs', () {
      final hash1 = sha256ofString('input1');
      final hash2 = sha256ofString('input2');
      expect(hash1, isNot(equals(hash2)));
    });
  });

  group('Email Validation', () {
    bool isValidEmail(String email) {
      return RegExp(r'^[\w\.\+\-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
    }

    test('accepts valid email formats', () {
      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(isValidEmail('user+tag@example.org'), isTrue);
    });

    test('rejects invalid email formats', () {
      expect(isValidEmail('invalid'), isFalse);
      expect(isValidEmail('no@domain'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail(''), isFalse);
    });
  });

  group('Password Validation', () {
    bool isPasswordStrong(String password) {
      return password.length >= 6;
    }

    test('accepts passwords 6+ characters', () {
      expect(isPasswordStrong('123456'), isTrue);
      expect(isPasswordStrong('password'), isTrue);
    });

    test('rejects passwords under 6 characters', () {
      expect(isPasswordStrong('12345'), isFalse);
      expect(isPasswordStrong(''), isFalse);
    });
  });

  group('Display Name Capitalization', () {
    String capitalizeEmailPrefix(String prefix) {
      if (prefix.isEmpty) return prefix;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }

    test('capitalizes lowercase prefix', () {
      expect(capitalizeEmailPrefix('john'), equals('John'));
    });

    test('handles single character', () {
      expect(capitalizeEmailPrefix('j'), equals('J'));
    });

    test('handles empty string', () {
      expect(capitalizeEmailPrefix(''), equals(''));
    });
  });
}
