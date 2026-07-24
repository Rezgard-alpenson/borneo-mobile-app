// [NONAKTIF]: import 'package:shared_preferences/shared_preferences.dart'; // Tidak lagi menggunakan penyimpanan IP manual di SharedPreferences

// ===============================================================
// --- BAGIAN: PENGATURAN DAN PENYIMPANAN ALAMAT IP SERVER ---
// ===============================================================
class ApiConfig {
  // Alamat IP Utama yang berjalan tetap di server kampus
  static const String _baseUrl = "https://eis.wicida.ac.id"; 
  static String get baseUrl => _baseUrl;

  /* ===============================================================
  // --- [NONAKTIF]: FITUR GANTI IP MANUAL (DARI SHAREDPREFERENCES) ---
  // Ditutup karena backend sudah berjalan tetap di server kampus (eis.wicida.ac.id)
  // ===============================================================
  static String get currentIpOnly {
    return _baseUrl
        .replaceAll("http://", "")
        .replaceAll("https://", "")
        .replaceAll(":8000", "")
        .trim();
  }

  static Future<void> loadSavedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString('server_ip');
      if (savedIp != null && savedIp.isNotEmpty) {
        if (savedIp.startsWith("http")) {
          _baseUrl = savedIp;
        } else {
          _baseUrl = "http://$savedIp:8000";
        }
        print(">>> [API CONFIG] Berhasil memuat IP server dari memori: $_baseUrl <<<");
      }
    } catch (e) {
      print(">>> [API CONFIG] Gagal memuat IP: $e <<<");
    }
  }

  static Future<void> setServerIp(String newIp) async {
    String formattedIp = newIp.trim();
    if (!formattedIp.startsWith("http")) {
      if (formattedIp.contains(".ac.id") || formattedIp.contains(".com") || formattedIp.contains(".io") || formattedIp.contains(".net") || formattedIp.contains(".org")) {
        formattedIp = "https://$formattedIp";
      } else if (!formattedIp.contains(":")) {
        formattedIp = "http://$formattedIp:8000";
      } else {
        formattedIp = "http://$formattedIp";
      }
    }
    _baseUrl = formattedIp;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', formattedIp);
      print(">>> [API CONFIG] Alamat IP server baru berhasil disimpan: $_baseUrl <<<");
    } catch (e) {
      print(">>> [API CONFIG] Gagal menyimpan IP: $e <<<");
    }
  }
  =============================================================== */

  // ===============================================================
  // --- BAGIAN: DAFTAR ENDPOINT API (URL TUJUAN BACKEND) ---
  // ===============================================================
  static String get login => "$baseUrl/api/login"; 
  static String getLatestSensor(int zoneId) => "$baseUrl/api/zones/$zoneId/sensor/latest";
  static String get getAllZones => "$baseUrl/api/zones";
  static String get createZone => "$baseUrl/api/zones/create";
  static String get controlPump => "$baseUrl/api/pump/control";
  static String getZoneById(int zoneId) => "$baseUrl/api/zones/$zoneId";
  static String get createUser => "$baseUrl/api/users/create";
  static String get changePassword => "$baseUrl/api/users/change-password";
  static String getZoneAlerts(int zoneId) => "$baseUrl/api/zones/$zoneId/alerts";
  static String exportSensorData(int zoneId) => "$baseUrl/api/zones/$zoneId/export/sensor";
  static String getSensorHistory(int zoneId) => "$baseUrl/api/zones/$zoneId/sensor/history";
}