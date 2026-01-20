import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/history_service.dart';
import '../../shared/components/components.dart';
import '../../shared/theme/app_colors.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<SavedGeneration> _allHistory = [];
  List<SavedGeneration> _filteredHistory = [];
  Map<Occasion, int> _occasionCounts = {};
  Occasion? _selectedOccasion;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final historyService = ref.read(historyServiceProvider);
    final history = await historyService.getHistory();
    if (mounted) {
      setState(() {
        _allHistory = history;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    // Pre-compute occasion counts once (O(n) instead of O(n²) in sorting)
    _occasionCounts = {};
    for (final item in _allHistory) {
      final occasion = item.result.occasion;
      _occasionCounts[occasion] = (_occasionCounts[occasion] ?? 0) + 1;
    }

    var filtered = _allHistory;

    // Filter by occasion
    if (_selectedOccasion != null) {
      filtered = filtered
          .where((item) => item.result.occasion == _selectedOccasion)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        // Search in message texts
        for (final message in item.result.messages) {
          if (message.text.toLowerCase().contains(query)) {
            return true;
          }
        }
        // Search in recipient name
        if (item.result.recipientName?.toLowerCase().contains(query) ?? false) {
          return true;
        }
        return false;
      }).toList();
    }

    _filteredHistory = filtered;
  }

  void _onOccasionFilterChanged(Occasion? occasion) {
    setState(() {
      _selectedOccasion = occasion;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    // Debounce search to avoid rebuilds on every keystroke
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _applyFilters();
        });
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedOccasion = null;
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  Future<void> _deleteItem(String id) async {
    final historyService = ref.read(historyServiceProvider);
    await historyService.deleteGeneration(id);
    _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Delete all saved messages? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final historyService = ref.read(historyServiceProvider);
      await historyService.clearHistory();
      _loadHistory();
    }
  }

  /// Get unique occasions from history for filter chips (sorted by frequency)
  List<Occasion> get _availableOccasions {
    final occasions = _occasionCounts.keys.toList();
    occasions.sort(
      (a, b) => (_occasionCounts[b] ?? 0).compareTo(_occasionCounts[a] ?? 0),
    );
    return occasions;
  }

  bool get _hasActiveFilters =>
      _selectedOccasion != null || _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Message History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: AppBackButton(onPressed: () => context.pop()),
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.textSecondary,
              ),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _allHistory.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Filter chips
                if (_availableOccasions.length > 1)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('All (${_allHistory.length})'),
                            selected: _selectedOccasion == null,
                            onSelected: (_) => _onOccasionFilterChanged(null),
                            selectedColor: AppColors.primaryLight,
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _selectedOccasion == null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _selectedOccasion == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Occasion chips
                        ..._availableOccasions.take(6).map((occasion) {
                          final count = _occasionCounts[occasion] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Text(
                                occasion.emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              label: Text('${occasion.label} ($count)'),
                              selected: _selectedOccasion == occasion,
                              onSelected: (_) =>
                                  _onOccasionFilterChanged(occasion),
                              selectedColor: AppColors.primaryLight,
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: _selectedOccasion == occasion
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: _selectedOccasion == occasion
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Results count & clear filters
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredHistory.length} result${_filteredHistory.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),

                // History list
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? _buildNoResultsState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredHistory.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _filteredHistory.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 24,
                                ),
                                child: Center(
                                  child: _buildDeviceOnlyDisclaimer(),
                                ),
                              );
                            }
                            final item = _filteredHistory[index];
                            return _HistoryCard(
                              item: item,
                              onDelete: () => _deleteItem(item.id),
                              searchQuery: _searchQuery,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your generated messages will appear here',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildDeviceOnlyDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceOnlyDisclaimer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smartphone, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          'History is stored on this device only',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No messages found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  const _HistoryCard({
    required this.item,
    required this.onDelete,
    this.searchQuery = '',
  });

  final SavedGeneration item;
  final VoidCallback onDelete;
  final String searchQuery;

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;
  int? _copiedIndex;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${DateFormat.jm().format(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${DateFormat.jm().format(date)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  Future<void> _copyMessage(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedIndex = index);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied!'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copiedIndex = null);
    }
  }

  Future<void> _shareMessage(String text) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '$text\n\n— Created with Prosepal',
        subject: 'Message from Prosepal',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.item.result;
    final occasion = result.occasion;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: occasion.borderColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: occasion.backgroundColor,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(14),
                    bottom: _isExpanded
                        ? Radius.zero
                        : const Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: occasion.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          occasion.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.recipientName?.isNotEmpty == true
                                ? result.recipientName!
                                : '${result.tone.label} ${result.relationship.label}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${occasion.label} • ${_formatDate(widget.item.savedAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (_isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.messages.length} message options',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.messages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final message = entry.value;
                      return _MessageItem(
                        index: index,
                        text: message.text,
                        isCopied: _copiedIndex == index,
                        onCopy: () => _copyMessage(message.text, index),
                        onShare: () => _shareMessage(message.text),
                      );
                    }),
                  ],
                ),
              ),
              // Delete button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Message'),
                        content: const Text(
                          'Are you sure you want to delete this message?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.onDelete();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.index,
    required this.text,
    required this.isCopied,
    required this.onCopy,
    required this.onShare,
  });

  final int index;
  final String text;
  final bool isCopied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Option ${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _SmallButton(icon: Icons.share_outlined, onPressed: onShare),
              const SizedBox(width: 8),
              _SmallButton(
                icon: isCopied ? Icons.check : Icons.copy,
                label: isCopied ? 'Copied' : 'Copy',
                isPrimary: true,
                onPressed: onCopy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final String? label;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 10 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPrimary ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? AppColors.primary : AppColors.textSecondary,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
