import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/sensor_model.dart';

// --- FASE 1: MANAJEMEN SESI & RBAC (ANGRAF) ---
class SessionManager {
  static String? token;
  static String? role;
  static int? userId;
  static String? username;

  static bool get isAdmin => role == 'admin' || role == 'super_admin';

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (token != null) "Authorization": "Bearer $token",
  };

  static void clear() {
    token = null;
    role = null;
    userId = null;
    username = null;
  }
}

class ApiService {
  Exception _handleNetworkError(Object e) {
    final errStr = e.toString();
    if (errStr.contains("TimeoutException") || errStr.contains("timed out") || errStr.contains("Timeout")) {
      return Exception('Waktu koneksi habis (Timeout 6 detik)! Server (${ApiConfig.currentIpOnly}) tidak merespons. Pastikan server Docker/Backend sudah dinyalakan dan HP di jaringan Wi-Fi yang sama.');
    }
    if (errStr.contains("SocketException") || errStr.contains("Connection refused") || errStr.contains("Failed host lookup") || errStr.contains("Network is unreachable") || errStr.contains("No route to host") || errStr.contains("ClientException")) {
      return Exception('Gagal terhubung ke server (${ApiConfig.currentIpOnly}). Pastikan server Docker/Backend sudah dinyalakan.');
    }
    return Exception(errStr.replaceAll("Exception: ", ""));
  }
  // Fungsi untuk Login dengan Penyimpanan Token JWT & Role RBAC
  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SessionManager.token = data['access_token'];
        SessionManager.role = data['role'];
        SessionManager.userId = data['user_id'];
        SessionManager.username = data['username'];
        print(">>> [JWT ACTIVE] Sesi tersimpan untuk '${SessionManager.username}' (Role: ${SessionManager.role}) <<<");
        return true; 
      } else {
        print(">>> [LOGIN GAGAL] HTTP ${response.statusCode}: ${response.body}");
        return false; 
      }
    } catch (e) {
      print(">>> ERROR KONEKSI LOGIN: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // Fungsi untuk mengambil data sensor dengan proteksi token JWT
  Future<SensorData> fetchLatestSensor(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getLatestSensor(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return SensorData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal mengambil data dari server, kode: ${response.statusCode}');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // Fungsi baru untuk mendaftarkan Zona & MAC Address ESP32 (Revisi Sempro)
  Future<bool> createNewZone({
    required String namaZona,
    required String deskripsi,
    required String macAddress,
    required double batasBawah,
    required double batasAtas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createZone),
        headers: SessionManager.headers,
        body: jsonEncode({
          "nama_zona": namaZona,
          "deskripsi": deskripsi,
          "mac_address": macAddress,
          "batas_bawah": batasBawah,
          "batas_atas": batasAtas,
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Gagal menambahkan zona');
      }
    } catch (e) {
      print(">>> ERROR CREATE ZONE: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // --- FITUR RBAC EKSEKUTOR: KENDALI POMPA MANUAL ---
  Future<bool> controlPump(int zoneId, String statusPompa) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.controlPump),
        headers: SessionManager.headers,
        body: jsonEncode({
          "zone_id": zoneId,
          "status_pompa": statusPompa,
          "dipicu_oleh": "Manual (Aplikasi - ${SessionManager.username ?? 'Admin'})",
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Akses Ditolak! Anda masuk sebagai Viewer.');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Gagal mengontrol pompa');
      }
    } catch (e) {
      print(">>> ERROR CONTROL PUMP: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // --- FITUR REVISI SEMPRO: BACA & UBAH THRESHOLD ZONA ---
  Future<Map<String, dynamic>> fetchZoneConfig(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getZoneById(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal membaca konfigurasi zona $zoneId');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  Future<bool> updateZoneConfig(int zoneId, {double? batasBawah, double? batasAtas, String? macAddress, String? namaZona}) async {
    try {
      final Map<String, dynamic> bodyData = {};
      if (batasBawah != null) bodyData["batas_bawah"] = batasBawah;
      if (batasAtas != null) bodyData["batas_atas"] = batasAtas;
      if (macAddress != null) bodyData["mac_address"] = macAddress;
      if (namaZona != null) bodyData["nama_zona"] = namaZona;

      final response = await http.put(
        Uri.parse(ApiConfig.getZoneById(zoneId)),
        headers: SessionManager.headers,
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('Akses Ditolak! Khusus Eksekutor (Admin).');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Gagal memperbarui threshold');
      }
    } catch (e) {
      print(">>> ERROR UPDATE ZONE: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // --- MANAJEMEN USER & GANTI PASSWORD ---
  Future<bool> createUser({required String username, required String email, required String password, required String role}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createUser),
        headers: SessionManager.headers,
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "role": role,
          "pembuat_id": SessionManager.userId ?? 1,
        }),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Gagal membuat user baru');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePassword),
        headers: SessionManager.headers,
        body: jsonEncode({
          "old_password": oldPassword,
          "new_password": newPassword,
        }),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Gagal mengganti password');
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // --- FITUR SARAN 2: SMART ALERTING SYSTEM ---
  Future<Map<String, dynamic>> fetchZoneAlerts(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getZoneAlerts(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal memuat notifikasi zona");
      }
    } catch (e) {
      return {"zone_id": zoneId, "nama_zona": "Zona $zoneId", "alerts": []};
    }
  }

  // --- FITUR SARAN 3: CSV EXPORT REPORT ---
  Future<String> fetchExportCsv(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.exportSensorData(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Gagal memuat laporan CSV");
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // --- FITUR BARU: GRAFIK RIWAYAT SENSOR TIME-SERIES ---
  Future<List<SensorData>> fetchSensorHistory(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSensorHistory(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);
        return dataList.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception("Gagal memuat riwayat sensor");
      }
    } catch (e) {
      print(">>> ERROR FETCH HISTORY: $e <<<");
      return [];
    }
  }
}