class ApiConfig {
  // --- PILIHAN MODE PENGUJIAN SERVER ---
  
  // 1. Mode USB Debugging via Kabel USB (Aktifkan ini + jalankan 'adb reverse tcp:8000 tcp:8000' di terminal laptop)
  // static const String baseUrl = "http://127.0.0.1:8000"; 
  
  // 2. Mode Wi-Fi Lokal (Pastikan HP & Laptop terhubung ke Wi-Fi yang sama)
  static const String baseUrl = "http://192.168.1.8:8000"; 
  
  // 3. Mode Server Kampus (Ganti dengan IP / Domain dari Faidil nanti)
  // static const String baseUrl = "http://IP_SERVER_KAMPUS:8000";
  
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
}