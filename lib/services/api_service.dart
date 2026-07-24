import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/sensor_model.dart';

// ===============================================================
// --- BAGIAN: MANAJEMEN SESI PENGGUNA & AKSES ROLE (RBAC) ---
// ===============================================================
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

// ===============================================================
// --- BAGIAN: KELAS UTAMA PENGHUBUNG KONEKSI DAN REQUEST KE BACKEND ---
// ===============================================================
class ApiService {
  Exception _handleNetworkError(Object e) {
    final errStr = e.toString();
    if (errStr.contains("TimeoutException") || errStr.contains("timed out") || errStr.contains("Timeout")) {
      return Exception('Waktu koneksi habis (Timeout 6 detik)! Server (${ApiConfig.baseUrl}) tidak merespons. Pastikan koneksi internet aktif.');
    }
    if (errStr.contains("SocketException") || errStr.contains("Connection refused") || errStr.contains("Failed host lookup") || errStr.contains("Network is unreachable") || errStr.contains("No route to host") || errStr.contains("ClientException")) {
      return Exception('Gagal terhubung ke server (${ApiConfig.baseUrl}). Pastikan koneksi internet aktif.');
    }
    return Exception(errStr.replaceAll("Exception: ", ""));
  }

  // Helper universal untuk mengambil data dari response (baik format langsung maupun wrapper {success, message, data})
  dynamic _extractPayload(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('data') && decoded['data'] != null) {
      return decoded['data'];
    }
    return decoded;
  }

  // Helper universal untuk membaca pesan error dari response backend
  String _extractError(http.Response response, String defaultMsg) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message'] ?? decoded['detail'] ?? defaultMsg;
      }
    } catch (_) {}
    return defaultMsg;
  }

  // ===============================================================
  // --- BAGIAN: FUNGSI LOGIN & PEMBUATAN TOKEN SESI ---
  // ===============================================================
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
        final decoded = jsonDecode(response.body);
        final payload = _extractPayload(response);
        final payloadMap = (payload is Map<String, dynamic>) ? payload : (decoded is Map<String, dynamic> ? decoded : {});

        SessionManager.token = payloadMap['access_token'] ?? decoded['access_token'];
        SessionManager.role = payloadMap['role'] ?? decoded['role'];
        SessionManager.userId = payloadMap['user_id'] ?? decoded['user_id'];
        SessionManager.username = payloadMap['username'] ?? decoded['username'];
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

  // ===============================================================
  // --- BAGIAN: PENGAMBILAN DATA SENSOR TERKINI (TELEMETRI) ---
  // ===============================================================
  Future<SensorData> fetchLatestSensor(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getLatestSensor(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final payload = _extractPayload(response);
        return SensorData.fromJson(payload);
      } else {
        final err = _extractError(response, '');
        if (err.contains("Belum ada data") || response.statusCode == 404) {
          return SensorData(
            kelembapanTanah: 0.0,
            suhuUdara: 0.0,
            kelembapanUdara: 0.0,
            phTanah: 0.0,
            debitAir: 0.0,
            statusHujan: false,
            waktuRekam: "Belum Ada Data Sensor (Menunggu ESP32)",
          );
        }
        throw Exception(err.isNotEmpty ? err : 'Gagal mengambil data sensor dari server (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains("Belum ada data")) {
        return SensorData(
          kelembapanTanah: 0.0,
          suhuUdara: 0.0,
          kelembapanUdara: 0.0,
          phTanah: 0.0,
          debitAir: 0.0,
          statusHujan: false,
          waktuRekam: "Belum Ada Data Sensor (Menunggu ESP32)",
        );
      }
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: PENAMBAHAN ZONA BARU & REGISTRASI MAC ADDRESS ESP32 ---
  // ===============================================================
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
        throw Exception(_extractError(response, 'Gagal menambahkan zona'));
      }
    } catch (e) {
      print(">>> ERROR CREATE ZONE: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: KENDALI POMPA AIR (REAL-TIME SWITCH VIA BACKEND/MQTT) ---
  // ===============================================================
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
        throw Exception(_extractError(response, 'Gagal mengontrol pompa'));
      }
    } catch (e) {
      print(">>> ERROR CONTROL PUMP: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: PENGAMBILAN & PENGATURAN AMBANG BATAS (THRESHOLD) ---
  // ===============================================================
  Future<Map<String, dynamic>> fetchZoneConfig(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getZoneById(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = _extractPayload(response);
        return (payload is Map<String, dynamic>) ? payload : {};
      } else {
        throw Exception(_extractError(response, 'Gagal membaca konfigurasi zona $zoneId'));
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
        throw Exception(_extractError(response, 'Gagal memperbarui threshold'));
      }
    } catch (e) {
      print(">>> ERROR UPDATE ZONE: $e <<<");
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: MANAJEMEN AKUN PENGGUNA & GANTI KATA SANDI ---
  // ===============================================================
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
        throw Exception(_extractError(response, 'Gagal membuat user baru'));
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
        throw Exception(_extractError(response, 'Gagal mengganti password'));
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: PENGAMBILAN NOTIFIKASI DARURAT (SMART ALERTING) ---
  // ===============================================================
  Future<Map<String, dynamic>> fetchZoneAlerts(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getZoneAlerts(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = _extractPayload(response);
        return (payload is Map<String, dynamic>) ? payload : {"zone_id": zoneId, "nama_zona": "Zona $zoneId", "alerts": []};
      } else {
        throw Exception("Gagal memuat notifikasi zona");
      }
    } catch (e) {
      return {"zone_id": zoneId, "nama_zona": "Zona $zoneId", "alerts": []};
    }
  }

  // ===============================================================
  // --- BAGIAN: EKSPOR DATA RIWAYAT KE FORMAT LAPORAN CSV ---
  // ===============================================================
  Future<String> fetchExportCsv(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.exportSensorData(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = _extractPayload(response);
        return (payload is String) ? payload : response.body;
      } else {
        throw Exception("Gagal memuat laporan CSV");
      }
    } catch (e) {
      throw _handleNetworkError(e);
    }
  }

  // ===============================================================
  // --- BAGIAN: PENGAMBILAN DATA RIWAYAT UNTUK GRAFIK (TIME-SERIES) ---
  // ===============================================================
  Future<List<SensorData>> fetchSensorHistory(int zoneId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSensorHistory(zoneId)),
        headers: SessionManager.headers,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final payload = _extractPayload(response);
        final List<dynamic> dataList = (payload is List) ? payload : [];
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