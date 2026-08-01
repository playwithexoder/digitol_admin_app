import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrintHistoryItem {
  final String id;
  final String fileName;
  final String category;
  final int copies;
  final DateTime date;
  final double estimatedPrice;
  String status;

  PrintHistoryItem({
    required this.id,
    required this.fileName,
    required this.category,
    required this.copies,
    required this.date,
    required this.estimatedPrice,
    this.status = 'uploaded',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'category': category,
        'copies': copies,
        'date': date.toIso8601String(),
        'estimatedPrice': estimatedPrice,
        'status': status,
      };

  factory PrintHistoryItem.fromJson(Map<String, dynamic> json) => PrintHistoryItem(
        id: json['id'],
        fileName: json['fileName'],
        category: json['category'],
        copies: json['copies'],
        date: DateTime.parse(json['date']),
        estimatedPrice: (json['estimatedPrice'] ?? 0).toDouble(),
        status: json['status'] ?? 'uploaded',
      );
}

class HistoryService {
  static const String _key = 'print_history';

  Future<List<PrintHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList.map((e) => PrintHistoryItem.fromJson(jsonDecode(e))).toList();
  }

  Future<void> addHistoryItem(PrintHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    list.insert(0, item); // Add to top
    // Keep only last 50 items
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }
    final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> updateHistoryItemStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index].status = newStatus;
      final jsonList = list.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_key, jsonList);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
