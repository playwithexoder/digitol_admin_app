import 'package:flutter/material.dart';

class ConnectionErrorCard extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onReconnect;

  const ConnectionErrorCard({
    super.key,
    required this.onDismiss,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Connection Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The Digitol Print PC server is currently offline or unreachable. Please ensure the local PC server is turned on, or connect to the correct Wi-Fi network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
                ElevatedButton(
                  onPressed: onReconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Reconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
