import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/history_service.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  final ApiService _apiService = ApiService();
  List<PrintHistoryItem> _history = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory().then((_) {
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_history.isEmpty) return;

      bool hasChanges = false;
      for (int i = 0; i < _history.length; i++) {
        final item = _history[i];
        final status = item.status.toLowerCase();
        final isTerminal = ['completed', 'failed', 'cancelled', 'error'].contains(status);

        if (!isTerminal && item.id.isNotEmpty) {
          try {
            final data = await _apiService.pollJobStatus(item.id);
            if (data != null && data['status'] != null && data['status'] != item.status) {
              _history[i].status = data['status'];
              await _historyService.updateHistoryItemStatus(item.id, data['status']);
              hasChanges = true;
            }
          } catch (_) {
            // Ignore polling errors
          }
        }
      }

      if (hasChanges && mounted) {
        setState(() {});
      }
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'document':
        return Icons.description;
      case 'photo':
        return Icons.photo;
      case 'passport':
        return Icons.person;
      default:
        return Icons.print;
    }
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') return Colors.green;
    if (s == 'failed' || s == 'cancelled' || s == 'error') return Colors.red;
    if (s == 'printing') return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Print History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () async {
              await _historyService.clearHistory();
              _loadHistory();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No print history yet.', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Your recent print jobs will appear here.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final statusColor = _getStatusColor(item.status);
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/tracking', extra: item.id),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getCategoryIcon(item.category), color: theme.colorScheme.primary),
                          ),
                          title: Text(item.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${DateFormat.yMMMd().format(item.date)} at ${DateFormat.jm().format(item.date)}\nCopies: ${item.copies}',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.status.toLowerCase() == 'completed' ? Icons.check_circle : 
                                item.status.toLowerCase() == 'failed' ? Icons.error :
                                item.status.toLowerCase() == 'printing' ? Icons.print : Icons.hourglass_empty,
                                color: statusColor, 
                                size: 20
                              ),
                              const SizedBox(height: 4),
                              Text(item.status.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
