import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'history_service.dart';

class ApiService {
  static const String _serverIpKey = 'server_ip';
  static const String _tunnelUrlKey = 'tunnel_url';
  static const String _accessKeyKey = 'access_key';
  static const String _customerNameKey = 'customer_name';
  static const String _customerPhoneKey = 'customer_phone';
  
  static const _secureStorage = FlutterSecureStorage();

  // Get saved Server IP (Local)
  Future<String?> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverIpKey);
  }

  // Save Server IP (Local)
  Future<void> saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ip);
  }

  // Get saved Tunnel URL (Remote)
  Future<String?> getTunnelUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tunnelUrlKey);
  }

  // Save Tunnel URL (Remote)
  Future<void> saveTunnelUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tunnelUrlKey, url);
  }

  // Get saved Access Key
  Future<String?> getAccessKey() async {
    return await _secureStorage.read(key: _accessKeyKey);
  }

  // Save Access Key
  Future<void> saveAccessKey(String key) async {
    await _secureStorage.write(key: _accessKeyKey, value: key);
  }

  // Get saved Customer Name
  Future<String?> getCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerNameKey);
  }

  // Save Customer Name
  Future<void> saveCustomerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerNameKey, name);
  }

  // Get saved Customer Phone
  Future<String?> getCustomerPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerPhoneKey);
  }

  // Save Customer Phone
  Future<void> saveCustomerPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerPhoneKey, phone);
  }

  // Upload print job to server
  Future<Map<String, dynamic>> uploadPrintJob({
    List<PlatformFile>? files,
    List<http.MultipartFile>? fileBytes,
    required String category, // 'document', 'photo', 'passport'
    int copies = 1,
    int pageCount = 1,
    String colorMode = 'color',
    String paperSize = 'a4',
    String paperQuality = 'standard_70',
    String printSides = 'single',
    String orientation = 'portrait',
    String imageLayout = 'full_page',
    String? customerName,
    String? customerPhone,
  }) async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    
    // Auto-fetch account info if not explicitly passed
    customerName ??= await getCustomerName() ?? 'Walk-in Customer';
    customerPhone ??= await getCustomerPhone() ?? '';
    
    if (customerName.trim().isEmpty) customerName = 'Walk-in Customer';
    
    String? activeHost;
    
    // Priority: Tunnel URL > Local IP
    if (tunnel != null && tunnel.isNotEmpty) {
      activeHost = tunnel;
    } else if (ip != null && ip.isNotEmpty) {
      activeHost = ip;
    }

    if (activeHost == null) {
      throw Exception('Server IP or Tunnel URL is not set. Please set it in Settings.');
    }

    Uri uri;
    if (activeHost.startsWith('http://') || activeHost.startsWith('https://')) {
      // It's a full URL (e.g., https://my-tunnel.loca.lt)
      final baseUrl = activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length - 1) : activeHost;
      uri = Uri.parse('$baseUrl/api/upload');
    } else {
      // It's a local IP (e.g., 192.168.0.131)
      uri = Uri.parse('http://$activeHost:8080/api/upload');
    }
    final request = http.MultipartRequest('POST', uri);
    final accessKey = await getAccessKey();
    if (accessKey != null && accessKey.isNotEmpty) {
      request.headers['x-access-key'] = accessKey;
    }

    // Add fields
    request.fields['category'] = category;
    request.fields['copies'] = copies.toString();
    request.fields['pageCount'] = pageCount.toString();
    request.fields['colorMode'] = colorMode;
    request.fields['paperSize'] = paperSize;
    request.fields['paperQuality'] = paperQuality;
    request.fields['printSides'] = printSides;
    request.fields['orientation'] = orientation;
    request.fields['imageLayout'] = imageLayout;
    request.fields['customerName'] = customerName;
    request.fields['customerPhone'] = customerPhone;

    // Add files
    if (files != null) {
      for (var file in files) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('files[]', file.bytes!, filename: file.name));
        } else if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath('files[]', file.path!));
        }
      }
    }
    if (fileBytes != null) {
      request.files.addAll(fileBytes);
    }

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } catch (e) {
      throw Exception('SERVER_OFFLINE');
    }
    
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = jsonDecode(response.body);
      
      // Save to history
      try {
        final fileName = files?.isNotEmpty == true 
            ? files!.first.name 
            : (fileBytes?.isNotEmpty == true && fileBytes!.first.filename != null) 
                ? fileBytes.first.filename! 
                : 'Document';

        await HistoryService().addHistoryItem(PrintHistoryItem(
          id: jsonResponse['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: fileName,
          category: category,
          copies: copies,
          date: DateTime.now(),
          estimatedPrice: 0.0,
          status: 'uploaded',
        ));
      } catch (e) {
        // Ignore history save errors
      }

      return jsonResponse;
    } else {
      throw Exception('Failed to upload job: ${response.body}');
    }
  }

  // Poll Job Status
  Future<Map<String, dynamic>?> pollJobStatus(String jobId) async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    
    String? activeHost;
    if (tunnel != null && tunnel.trim().isNotEmpty) {
      activeHost = tunnel;
    } else if (ip != null && ip.trim().isNotEmpty) {
      activeHost = ip;
    }

    if (activeHost == null) return null;

    String url;
    if (activeHost.startsWith('http://') || activeHost.startsWith('https://')) {
      final base = activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length - 1) : activeHost;
      url = '$base/api/job/$jobId';
    } else {
      url = 'http://$activeHost:8080/api/job/$jobId';
    }

    try {
      final accessKey = await getAccessKey() ?? '';
      final response = await http.get(
        Uri.parse(url),
        headers: {'x-access-key': accessKey},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      throw Exception('SERVER_OFFLINE');
    }
  }

  // --- ADMIN METHODS ---

  Future<List<Map<String, dynamic>>> fetchAdminJobs() async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    String? activeHost = (tunnel != null && tunnel.isNotEmpty) ? tunnel : ip;
    if (activeHost == null) throw Exception('No host');

    String url = activeHost.startsWith('http') 
        ? '${activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length-1) : activeHost}/api/admin/jobs'
        : 'http://$activeHost:8080/api/admin/jobs';

    final accessKey = await getAccessKey() ?? '';
    final response = await http.get(Uri.parse(url), headers: {'x-access-key': accessKey});
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<String?> getAdminFileUrl(String jobId) async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    String? activeHost = (tunnel != null && tunnel.isNotEmpty) ? tunnel : ip;
    if (activeHost == null) return null;

    String base = activeHost.startsWith('http')
        ? (activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length-1) : activeHost)
        : 'http://$activeHost:8080';
    return '$base/api/admin/jobs/$jobId/file';
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    String? activeHost = (tunnel != null && tunnel.isNotEmpty) ? tunnel : ip;
    if (activeHost == null) throw Exception('No host');

    String url = activeHost.startsWith('http') 
        ? '${activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length-1) : activeHost}/api/admin/jobs/$jobId/status'
        : 'http://$activeHost:8080/api/admin/jobs/$jobId/status';

    final accessKey = await getAccessKey() ?? '';
    final response = await http.post(
      Uri.parse(url), 
      headers: {'x-access-key': accessKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status})
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<void> deleteJob(String jobId) async {
    final ip = await getServerIp();
    final tunnel = await getTunnelUrl();
    String? activeHost = (tunnel != null && tunnel.isNotEmpty) ? tunnel : ip;
    if (activeHost == null) throw Exception('No host');

    String url = activeHost.startsWith('http') 
        ? '${activeHost.endsWith('/') ? activeHost.substring(0, activeHost.length-1) : activeHost}/api/admin/jobs/$jobId'
        : 'http://$activeHost:8080/api/admin/jobs/$jobId';

    final accessKey = await getAccessKey() ?? '';
    final response = await http.delete(Uri.parse(url), headers: {'x-access-key': accessKey});
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete job');
    }
  }
}

final apiServiceProvider = Provider((ref) => ApiService());

final adminJobsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchAdminJobs();
});
