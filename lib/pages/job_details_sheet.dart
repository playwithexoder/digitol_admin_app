import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class JobDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsSheet({super.key, required this.job});

  @override
  ConsumerState<JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends ConsumerState<JobDetailsSheet> {
  bool _isLoading = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateJobStatus(widget.job['id'], newStatus);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteJob() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteJob(widget.job['id']);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.job['status'] as String;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.job['customerName'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('File: ${widget.job['fileName']}')),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blueGrey),
                  tooltip: 'Preview File',
                  onPressed: () {
                    context.push('/file-preview', extra: widget.job);
                  },
                ),
              ],
            ),
            Text('Phone: ${widget.job['customerPhone']}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (status == 'uploaded' || status == 'reviewing')
                ElevatedButton(
                  onPressed: () => _updateStatus('queued'),
                  child: const Text('Approve & Queue'),
                ),
              const SizedBox(height: 8),
              if (status == 'queued' || status == 'printing')
                ElevatedButton(
                  onPressed: () => _updateStatus('completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Mark Completed'),
                ),
              const SizedBox(height: 8),
              if (status != 'cancelled' && status != 'completed')
                OutlinedButton(
                  onPressed: () => _updateStatus('cancelled'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Cancel Job'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _deleteJob,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete Permanently'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
