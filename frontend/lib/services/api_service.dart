import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../providers/settings_provider.dart';

class ApiService {
  final SettingsProvider settingsProvider;

  ApiService({required this.settingsProvider});

  String get baseUrl => settingsProvider.serverUrl;

  Future<List<Device>> getDevices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/devices'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Device> devices = body.map((dynamic item) => Device.fromJson(item)).toList();
        return devices;
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load devices: $e');
    }
  }

  Future<void> addDevice(Map<String, dynamic> deviceData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/devices'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(deviceData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add device: $e');
    }
  }

  Future<void> updateDevice(int id, Map<String, dynamic> deviceData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/devices/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(deviceData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }

  Future<void> deleteDevice(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/devices/$id'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete device: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete device: $e');
    }
  }

  Future<Map<String, dynamic>> checkDeviceStatus(String ip) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status/$ip'),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get status');
      }
    } catch (e) {
      throw Exception('Failed to check status: $e');
    }
  }

  Future<bool> testConnection(String tempUrl) async {
    try {
      final response = await http.get(Uri.parse('$tempUrl/api/devices')).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
