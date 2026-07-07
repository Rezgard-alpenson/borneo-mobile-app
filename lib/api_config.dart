import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Alamat IP Default (akan ditimpa otomatis jika ada IP yang disimpan pengguna di HP)
  static String _baseUrl = "http://192.168.1.12:8000"; 
  static String get baseUrl => _baseUrl;

  // Mengambil angka IP murni (misal: 192.168.1.12) untuk ditampilkan pada input form
  static String get currentIpOnly {
    return _baseUrl
        .replaceAll("http://", "")
        .replaceAll("https://", "")
        .replaceAll(":8000", "")
        .trim();
  }

  // Memuat IP yang tersimpan di memori HP saat aplikasi dijalankan
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

  // Menyimpan dan mengubah alamat IP server baru ke SharedPreferences
  static Future<void> setServerIp(String newIp) async {
    String formattedIp = newIp.trim();
    if (!formattedIp.startsWith("http")) {
      if (!formattedIp.contains(":")) {
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

  // Endpoint API
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