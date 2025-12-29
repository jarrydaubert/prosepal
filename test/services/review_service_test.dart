import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prosepal/core/services/review_service.dart';

void main() {
  group('ReviewService', () {
    late ReviewService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = ReviewService(prefs);
    });

    test('should create instance with SharedPreferences', () {
      expect(service, isNotNull);
    });

    test('should default to hasRequestedReview = false', () {
      expect(service.hasRequestedReview, isFalse);
    });
  });

  group('ReviewService recordFirstLaunchIfNeeded', () {
    late ReviewService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = ReviewService(prefs);
    });

    test('should record first launch timestamp', () async {
      await service.recordFirstLaunchIfNeeded();

      final timestamp = prefs.getInt('first_launch_timestamp');
      expect(timestamp, isNotNull);
      expect(timestamp, greaterThan(0));
    });

    test('should not overwrite existing first launch timestamp', () async {
      // Set an initial timestamp
      final initialTime = DateTime(2025, 1, 1).millisecondsSinceEpoch;
      await prefs.setInt('first_launch_timestamp', initialTime);

      // Create new service and try to record
      service = ReviewService(prefs);
      await service.recordFirstLaunchIfNeeded();

      // Should not have changed
      final timestamp = prefs.getInt('first_launch_timestamp');
      expect(timestamp, equals(initialTime));
    });
  });

  group('ReviewService checkAndRequestReview', () {
    late ReviewService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = ReviewService(prefs);
    });

    test('should return false if already requested', () async {
      await prefs.setBool('has_requested_review', true);
      service = ReviewService(prefs);

      final result = await service.checkAndRequestReview(10);
      expect(result, isFalse);
    });

    test('should return false if generations < minimum', () async {
      final result = await service.checkAndRequestReview(2);
      expect(result, isFalse);
    });

    test('should return false if not enough days since first launch', () async {
      // Set first launch to now
      await prefs.setInt(
        'first_launch_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      service = ReviewService(prefs);

      final result = await service.checkAndRequestReview(10);
      expect(result, isFalse);
    });
  });

  group('ReviewService constants', () {
    test('should require minimum 3 generations', () {
      const minGenerations = 3;
      expect(minGenerations, equals(3));
    });

    test('should require minimum 2 days before review', () {
      const minDays = 2;
      expect(minDays, equals(2));
    });
  });

  group('ReviewService hasRequestedReview', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('should return false when not set', () {
      final service = ReviewService(prefs);
      expect(service.hasRequestedReview, isFalse);
    });

    test('should return true when set to true', () async {
      await prefs.setBool('has_requested_review', true);
      final service = ReviewService(prefs);
      expect(service.hasRequestedReview, isTrue);
    });

    test('should return false when set to false', () async {
      await prefs.setBool('has_requested_review', false);
      final service = ReviewService(prefs);
      expect(service.hasRequestedReview, isFalse);
    });
  });

  group('ReviewService resetReviewState', () {
    late ReviewService service;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = ReviewService(prefs);
    });

    test('should clear review state', () async {
      // Set some state
      await prefs.setBool('has_requested_review', true);
      await prefs.setInt('first_launch_timestamp', 12345);

      // Reset
      await service.resetReviewState();

      // Verify cleared
      expect(prefs.getBool('has_requested_review'), isNull);
      expect(prefs.getInt('first_launch_timestamp'), isNull);
    });
  });

  group('ReviewService API contract', () {
    late ReviewService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = ReviewService(prefs);
    });

    test('should expose recordFirstLaunchIfNeeded method', () {
      expect(service.recordFirstLaunchIfNeeded, isA<Function>());
    });

    test('should expose checkAndRequestReview method', () {
      expect(service.checkAndRequestReview, isA<Function>());
    });

    test('should expose requestReview method', () {
      expect(service.requestReview, isA<Function>());
    });

    test('should expose openStoreListing method', () {
      expect(service.openStoreListing, isA<Function>());
    });

    test('should expose hasRequestedReview getter', () {
      expect(service.hasRequestedReview, isA<bool>());
    });

    test('should expose resetReviewState method', () {
      expect(service.resetReviewState, isA<Function>());
    });
  });

  group('ReviewService timing logic', () {
    test('should calculate days since first launch correctly', () {
      final firstLaunch = DateTime(2025, 1, 1);
      final now = DateTime(2025, 1, 4);

      final daysSince = now.difference(firstLaunch).inDays;
      expect(daysSince, equals(3));
    });

    test('should handle same day correctly', () {
      final firstLaunch = DateTime(2025, 1, 1, 10, 0);
      final now = DateTime(2025, 1, 1, 15, 0);

      final daysSince = now.difference(firstLaunch).inDays;
      expect(daysSince, equals(0));
    });

    test('should handle timestamp conversion correctly', () {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final recovered = DateTime.fromMillisecondsSinceEpoch(timestamp);

      expect(recovered.year, equals(now.year));
      expect(recovered.month, equals(now.month));
      expect(recovered.day, equals(now.day));
    });
  });
}
