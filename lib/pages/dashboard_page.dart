import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'job_details_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminJobsProvider),
          ),
        ],
      ),
      body: jobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No active jobs', style: TextStyle(color: AppColors.secondaryText)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminJobsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(context, ref, job);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Connection Error', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(adminJobsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, WidgetRef ref, Map<String, dynamic> job) {
    final status = job['status'] as String;
    final theme = Theme.of(context);
    
    Color statusColor = Colors.grey;
    if (status == 'uploaded' || status == 'reviewing') statusColor = AppColors.warning;
    if (status == 'queued' || status == 'printing') statusColor = AppColors.primaryTeal;
    if (status == 'completed') statusColor = AppColors.success;
    if (status == 'cancelled' || status == 'failed') statusColor = AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => JobDetailsSheet(job: job),
          ).then((_) {
            ref.invalidate(adminJobsProvider);
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job['customerName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.insert_drive_file_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(job['fileName'] ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${(job['totalPrice'] ?? 0).toString()}',
                    style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${job['pageCount'] ?? 0} Pages',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
