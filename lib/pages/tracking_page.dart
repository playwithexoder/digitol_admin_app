import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class TrackingPage extends StatefulWidget {
  final String jobId;
  final String? type;
  const TrackingPage({super.key, required this.jobId, this.type});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _status = 'checking';
  Timer? _timer;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final data = await _apiService.pollJobStatus(widget.jobId);
    if (mounted && data != null && data['status'] != null) {
      setState(() {
        _status = data['status'];
      });
    }
  }

  Map<String, dynamic> _getUiState() {
    final isRaw = widget.type == 'raw';
    switch (_status) {
      case 'uploaded':
      case 'queued':
      case 'reviewing':
        return {
          'icon': Icons.hourglass_empty,
          'title': isRaw ? 'Received in PC' : 'Queued in PC',
          'desc': isRaw ? 'Waiting for review in Queue...' : 'Waiting to start printing...',
          'color': Colors.orange,
        };
      case 'printing':
        return {
          'icon': isRaw ? Icons.visibility : Icons.print,
          'title': isRaw ? 'Reviewing...' : 'Printing...',
          'desc': isRaw ? 'Your files are currently being reviewed.' : 'Your files are currently being printed.',
          'color': Colors.blue,
        };
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'title': 'Completed',
          'desc': isRaw ? 'Your files have been processed!' : 'Your print is ready!',
          'color': Colors.green,
        };
      case 'error':
      case 'cancelled':
      case 'failed':
        return {
          'icon': Icons.error,
          'title': 'Failed or Cancelled',
          'desc': isRaw ? 'There was an issue processing these files.' : 'There was an issue printing this job.',
          'color': Colors.red,
        };
      default:
        return {
          'icon': Icons.search,
          'title': 'Checking Status',
          'desc': isRaw ? 'Looking up your files...' : 'Looking up your print job...',
          'color': Colors.grey,
        };
    }
  }

  String _getStatusLabel() {
    if (widget.type == 'raw') {
      if (_status == 'reviewing') return 'ACCEPTED';
      if (_status == 'completed') return 'SAVED';
    }
    return _status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ui = _getUiState();
    final theme = Theme.of(context);
    final color = ui['color'] as Color;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tracking Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ui['icon'] as IconData,
                  size: 50,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                ui['title'] as String,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                ui['desc'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Status: ${_getStatusLabel()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.type == 'raw' ? 'Send More Files' : 'Print More Files'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
