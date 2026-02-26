import 'package:prosepal/core/models/models.dart';
import 'package:prosepal/core/services/history_service.dart';

/// Mock implementation of HistoryService for testing
///
/// Supports:
/// - Configurable history data
/// - Call tracking
/// - In-memory storage (no secure storage dependency)
class MockHistoryService extends HistoryService {
  List<SavedGeneration> _mockHistory = [];

  // Call tracking
  int getHistoryCallCount = 0;
  int saveGenerationCallCount = 0;
  int deleteGenerationCallCount = 0;
  int clearHistoryCallCount = 0;

  String? lastDeletedId;
  GenerationResult? lastSavedResult;

  /// Set mock history data for tests
  void setHistory(List<SavedGeneration> history) {
    _mockHistory = List.from(history);
  }

  /// Add a single item to mock history
  void addHistoryItem(SavedGeneration item) {
    _mockHistory.insert(0, item);
  }

  /// Clear mock data
  void reset() {
    _mockHistory = [];
    getHistoryCallCount = 0;
    saveGenerationCallCount = 0;
    deleteGenerationCallCount = 0;
    clearHistoryCallCount = 0;
    lastDeletedId = null;
    lastSavedResult = null;
  }

  @override
  Future<List<SavedGeneration>> getHistory() async {
    getHistoryCallCount++;
    return List.from(_mockHistory);
  }

  @override
  Future<void> saveGeneration(GenerationResult result) async {
    saveGenerationCallCount++;
    lastSavedResult = result;

    final saved = SavedGeneration(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      result: result,
      savedAt: DateTime.now(),
    );
    _mockHistory.insert(0, saved);
  }

  @override
  Future<void> deleteGeneration(String id) async {
    deleteGenerationCallCount++;
    lastDeletedId = id;
    _mockHistory.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearHistory() async {
    clearHistoryCallCount++;
    _mockHistory.clear();
  }
}

/// Factory to create test SavedGeneration instances
class TestHistoryFactory {
  static SavedGeneration createItem({
    String? id,
    Occasion occasion = Occasion.birthday,
    Relationship relationship = Relationship.closeFriend,
    Tone tone = Tone.heartfelt,
    String? recipientName,
    List<String> messageTexts = const ['Test message 1', 'Test message 2'],
    DateTime? savedAt,
  }) {
    final now = DateTime.now();
    final messages = messageTexts
        .asMap()
        .entries
        .map(
          (entry) => GeneratedMessage(
            id: 'msg-${entry.key}',
            text: entry.value,
            occasion: occasion,
            relationship: relationship,
            tone: tone,
            createdAt: now,
            recipientName: recipientName,
          ),
        )
        .toList();

    return SavedGeneration(
      id: id ?? 'test-${now.millisecondsSinceEpoch}',
      result: GenerationResult(
        messages: messages,
        occasion: occasion,
        relationship: relationship,
        tone: tone,
        length: MessageLength.standard,
        recipientName: recipientName,
      ),
      savedAt: savedAt ?? now,
    );
  }

  static List<SavedGeneration> createMultipleItems(int count) {
    final occasions = [
      Occasion.birthday,
      Occasion.sympathy,
      Occasion.congrats,
      Occasion.thankYou,
    ];

    return List.generate(
      count,
      (index) => createItem(
        id: 'item-$index',
        occasion: occasions[index % occasions.length],
        savedAt: DateTime.now().subtract(Duration(days: index)),
      ),
    );
  }
}
