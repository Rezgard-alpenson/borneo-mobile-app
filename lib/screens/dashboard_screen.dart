import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/sensor_model.dart';
import 'login_screen.dart';

// Konstanta warna dari desain Sempro Anda
const Color utamaHijau = Color(0xFF1B5E20);

class DashboardScreen extends StatefulWidget {
  final bool isAdmin;
  
  const DashboardScreen({super.key, this.isAdmin = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Future<SensorData>? _sensorData;
  Future<Map<String, dynamic>>? _zoneConfig;

  void _refreshData() {
    setState(() {
      _sensorData = _apiService.fetchLatestSensor(1);
      _zoneConfig = _apiService.fetchZoneConfig(1);
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    _sensorData ??= _apiService.fetchLatestSensor(1);
    _zoneConfig ??= _apiService.fetchZoneConfig(1);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4), // latarAbu
      appBar: AppBar(
        backgroundColor: utamaHijau,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Column(
          children: [
            const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              widget.isAdmin ? 'Masuk sebagai: ADMIN' : 'Masuk sebagai: VIEWER',
              style: TextStyle(fontSize: 12, color: widget.isAdmin ? Colors.amberAccent : Colors.white70),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_rounded, size: 28),
            tooltip: "Menu Pengguna & Keamanan",
            onSelected: (val) {
              if (val == 'add_user') {
                _tampilkanDialogTambahUser(context);
              } else if (val == 'change_pwd') {
                _tampilkanDialogGantiPassword(context);
              } else if (val == 'logout') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              if (widget.isAdmin)
                const PopupMenuItem(
                  value: 'add_user',
                  child: Row(children: [Icon(Icons.person_add_alt_1_rounded, color: utamaHijau), SizedBox(width: 10), Text("Tambah Akun (by Email)")]),
                ),
              const PopupMenuItem(
                value: 'change_pwd',
                child: Row(children: [Icon(Icons.vpn_key_rounded, color: Colors.blue), SizedBox(width: 10), Text("Ganti Password Saya")]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout_rounded, color: Colors.red), SizedBox(width: 10), Text("Keluar (Logout)")]),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin ? FloatingActionButton.extended(
        backgroundColor: utamaHijau,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text("Tambah Zona", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _tampilkanDialogTambahZona(context),
      ) : null,
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Widget Cuaca (Statik dari desain Anda)
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.wb_sunny_rounded, size: 50, color: Colors.amberAccent),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuaca Saat Ini', style: TextStyle(color: Colors.white70)),
                      Text('Cerah Berkabut', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Monitoring Zona Real-Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Bagian Dinamis: Mengambil data dari FastAPI
          FutureBuilder<SensorData>(
            future: _sensorData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: utamaHijau));
              } else if (snapshot.hasError) {
                return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
              } else if (!snapshot.hasData) {
                return const Center(child: Text("Belum ada data sensor."));
              }

              final data = snapshot.data!;
              return _buatKartuZona(data);
            },
          ),
        ],
      ),
    );
  }

  // Fungsi pembuat UI kartu yang diadaptasi dari kode Sempro Anda
  Widget _buatKartuZona(SensorData data) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _zoneConfig,
      builder: (context, snapshot) {
        final config = snapshot.data ?? {
          "nama_zona": "Zona 1 (Kebun A)",
          "mac_address": "ESP32-ZONA-01",
          "batas_bawah": 40.0,
          "batas_atas": 80.0
        };
        final namaZona = config['nama_zona'] ?? "Zona 1 (Kebun A)";
        final macAddress = config['mac_address'] ?? "ESP32-ZONA-01";
        final batasBawah = (config['batas_bawah'] as num?)?.toDouble() ?? 40.0;
        final batasAtas = (config['batas_atas'] as num?)?.toDouble() ?? 80.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view_rounded, color: utamaHijau, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              namaZona,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 22),
                          tooltip: "Pusat Peringatan Dini",
                          onPressed: () => _tampilkanPusatNotifikasi(context, 1, namaZona),
                        ),
                        IconButton(
                          icon: const Icon(Icons.analytics_rounded, color: Colors.blue, size: 22),
                          tooltip: "Laporan & Analisa Panen",
                          onPressed: () => _tampilkanDialogLaporan(context, 1, namaZona),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: utamaHijau, size: 22),
                            tooltip: "Atur Batas Otomasi (Threshold)",
                            onPressed: () => _tampilkanDialogAturThreshold(context, 1, namaZona, batasBawah, batasAtas, macAddress),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Pompa OFF', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // --- INFORMASI THRESHOLD ZONA (HASIL REVISI SEMPRO) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory_rounded, size: 14, color: utamaHijau),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Otomasi ESP32 ($macAddress)",
                              style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text("ON < $batasBawah% | OFF > $batasAtas%", style: const TextStyle(fontSize: 11, color: utamaHijau, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoSensor(Icons.water_drop_outlined, 'Tanah', '${data.kelembapanTanah}%', Colors.blue),
                    _infoSensor(Icons.thermostat_outlined, 'Suhu', '${data.suhuUdara}°C', Colors.orange),
                    _infoSensor(Icons.science_outlined, 'pH', '${data.phTanah}', Colors.purple),
                  ],
                ),
                // --- ATURAN RBAC BORNEO AGRICOLA: SAKELAR POMPA KHUSUS ADMIN ---
                if (widget.isAdmin) ...[
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.power_settings_new_rounded, color: utamaHijau, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Kendali Pompa Manual (Eksekutor):",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: false, // Default atau status real-time
                        activeColor: utamaHijau,
                        onChanged: (val) async {
                          try {
                            await _apiService.controlPump(1, val ? "ON" : "OFF");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Instruksi pompa ${val ? 'ON' : 'OFF'} dikirim via MQTT!"), backgroundColor: utamaHijau),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoSensor(IconData ikon, String label, String nilai, Color warna) {
    return Column(
      children: [
        Icon(ikon, color: warna, size: 24),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(nilai, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
      ],
    );
  }

  // --- FITUR REVISI SEMPRO: DIALOG ATUR THRESHOLD OTOMASI PER ZONA ---
  void _tampilkanDialogAturThreshold(BuildContext context, int zoneId, String namaZona, double batasBawah, double batasAtas, String macAddress) {
    final namaCtrl = TextEditingController(text: namaZona);
    final bawahCtrl = TextEditingController(text: batasBawah.toString());
    final atasCtrl = TextEditingController(text: batasAtas.toString());
    final macCtrl = TextEditingController(text: macAddress);
    bool isSubmitting = false;
    bool isMacLocked = true; // Fitur keamanan: Kunci pengeditan MAC secara default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: utamaHijau, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text("Otomasi & Threshold $namaZona", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: utamaHijau)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Sesuai revisi Sempro: Logika pengairan dan ambang batas dieksekusi secara independen per zona.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(height: 24),
                    
                    // --- FIELD NAMA ZONA ---
                    TextField(
                      controller: namaCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama Zona Pertanian",
                        prefixIcon: const Icon(Icons.landscape_rounded, color: utamaHijau),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- FIELD MAC ADDRESS DENGAN GEMBOK PENGAMAN & KONFIRMASI ---
                    TextField(
                      controller: macCtrl,
                      readOnly: isMacLocked,
                      decoration: InputDecoration(
                        labelText: "MAC Address ESP32 (Perangkat Ican)",
                        prefixIcon: const Icon(Icons.memory_rounded, color: utamaHijau),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isMacLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                            color: isMacLocked ? Colors.grey : Colors.red,
                          ),
                          tooltip: isMacLocked ? "Klik untuk membuka kunci pengeditan MAC Address" : "MAC Address terbuka untuk diedit",
                          onPressed: () async {
                            if (isMacLocked) {
                              final konfirmasi = await showDialog<bool>(
                                context: ctx,
                                builder: (dCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                      SizedBox(width: 10),
                                      Expanded(child: Text("Perhatian Kritis!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                    ],
                                  ),
                                  content: const Text(
                                    "MAC Address adalah identitas perangkat keras ESP32 di lahan pertanian (sistem rekanan Ican).\n\n"
                                    "Apakah Anda yakin ingin membuka kunci dan mengubah alamat fisik ini? Jika salah ketik, sistem tidak dapat mengirim instruksi pompa air ke perangkat MQTT!",
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx, false),
                                      child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      onPressed: () => Navigator.pop(dCtx, true),
                                      child: const Text("Ya, Buka Kunci", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (konfirmasi == true) {
                                setModalState(() { isMacLocked = false; });
                              }
                            } else {
                              setModalState(() { isMacLocked = true; });
                            }
                          },
                        ),
                        filled: isMacLocked,
                        fillColor: isMacLocked ? Colors.grey.shade100 : Colors.red.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bawahCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Batas Bawah ON (%)",
                              helperText: "< ini Pompa Nyala",
                              prefixIcon: const Icon(Icons.water_drop_outlined, color: Colors.blue),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: atasCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Batas Atas OFF (%)",
                              helperText: "> ini Pompa Mati",
                              prefixIcon: const Icon(Icons.water_drop, color: Colors.green),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: utamaHijau,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting ? null : () async {
                          final b = double.tryParse(bawahCtrl.text.trim()) ?? 40.0;
                          final a = double.tryParse(atasCtrl.text.trim()) ?? 80.0;
                          if (b >= a) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Batas bawah harus lebih kecil dari batas atas!"), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          // --- CEK DAN KONFIRMASI JIKA ADA PERUBAHAN MAC ADDRESS ---
                          final baruMac = macCtrl.text.trim().toUpperCase();
                          if (baruMac != macAddress.toUpperCase()) {
                            final yakinGanti = await showDialog<bool>(
                              context: ctx,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.security_rounded, color: Colors.red, size: 28),
                                    SizedBox(width: 10),
                                    Expanded(child: Text("Konfirmasikan Perubahan MAC!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
                                  ],
                                ),
                                content: Text(
                                  "Anda akan mengubah MAC Address dari:\n'${macAddress}' ➔ '${baruMac}'.\n\n"
                                  "Pastikan alamat baru ini sesuai persis dengan ESP32 fisik yang terpasang di lapangan agar koneksi MQTT tidak terputus.",
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: utamaHijau, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text("Simpan & Ganti MAC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (yakinGanti != true) {
                              return; // Batal simpan jika user ragu/membatalkan
                            }
                          }

                          setModalState(() { isSubmitting = true; });
                          try {
                            await _apiService.updateZoneConfig(zoneId, batasBawah: b, batasAtas: a, macAddress: baruMac, namaZona: namaCtrl.text.trim());
                            if (ctx.mounted) Navigator.pop(ctx);
                            _refreshData(); // Segarkan UI agar threshold baru muncul
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Ambang batas otomasi dan pengaturan zona berhasil diperbarui!"), backgroundColor: utamaHijau),
                              );
                            }
                          } catch (e) {
                            setModalState(() { isSubmitting = false; });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Simpan Perubahan Threshold", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text("🎛️ Kendali Darurat Pompa Air (Manual Override)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 4),
                    const Text("Gunakan tombol ini untuk mematikan atau menyalakan pompa secara langsung saat hujan atau sensor error tanpa menunggu otomasi.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.power_settings_new_rounded),
                            label: const Text("NYALAKAN (ON)", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              try {
                                await _apiService.controlPump(zoneId, "ON");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Instruksi NYALAKAN pompa berhasil dikirim ke ESP32!"), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.stop_circle_rounded),
                            label: const Text("MATIKAN (OFF)", style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              try {
                                await _apiService.controlPump(zoneId, "OFF");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Instruksi MATIKAN pompa berhasil dikirim ke ESP32!"), backgroundColor: Colors.red),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FITUR REVISI SEMPRO: DIALOG PENAMBAHAN ZONA & MAC ADDRESS ESP32 ---
  void _tampilkanDialogTambahZona(BuildContext context) {
    final namaCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final batasBawahCtrl = TextEditingController(text: "40.0");
    final batasAtasCtrl = TextEditingController(text: "80.0");
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: utamaHijau.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add_location_alt_rounded, color: utamaHijau),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tambah Zona & Alat IoT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("Hubungkan MAC Address ESP32 Ican", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: namaCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama Zona (cth: Zona B - Tomat)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.landscape_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: macCtrl,
                      decoration: InputDecoration(
                        labelText: "MAC Address / ID ESP32 (cth: 24:6F:28:AB:CD:EF)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.memory_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deskripsiCtrl,
                      decoration: InputDecoration(
                        labelText: "Deskripsi Singkat (Opsi)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: batasBawahCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Batas Bawah ON (%)",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: batasAtasCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Batas Atas OFF (%)",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: utamaHijau,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: isSubmitting ? null : () async {
                          if (namaCtrl.text.isEmpty || macCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Nama Zona dan MAC Address wajib diisi!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setModalState(() { isSubmitting = true; });
                          try {
                            await _apiService.createNewZone(
                              namaZona: namaCtrl.text,
                              deskripsi: deskripsiCtrl.text,
                              macAddress: macCtrl.text,
                              batasBawah: double.tryParse(batasBawahCtrl.text) ?? 40.0,
                              batasAtas: double.tryParse(batasAtasCtrl.text) ?? 80.0,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Sukses! '${namaCtrl.text}' berhasil terikat dengan alat ${macCtrl.text}"),
                                  backgroundColor: utamaHijau,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() { isSubmitting = false; });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text("Error: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Daftarkan Zona & Alat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MANAJEMEN AKUN & GANTI PASSWORD ---
  void _tampilkanDialogTambahUser(BuildContext context) {
    final emailCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String rolePilihan = "viewer";
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: utamaHijau.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: utamaHijau),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tambah Akun Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("Daftarkan operator atau admin berdasarkan Email", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Pengguna (cth: operator@gmail.com)",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: userCtrl,
                      decoration: InputDecoration(
                        labelText: "Username Login (cth: operator_1)",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pwdCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password Awal (Sementara)",
                        helperText: "Berikan password ini ke user untuk login pertama kali",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Hak Akses (Role):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Viewer (Operator)", style: TextStyle(fontSize: 13)),
                            value: "viewer",
                            groupValue: rolePilihan,
                            onChanged: (val) => setModalState(() => rolePilihan = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Admin (Eksekutor)", style: TextStyle(fontSize: 13)),
                            value: "admin",
                            groupValue: rolePilihan,
                            onChanged: (val) => setModalState(() => rolePilihan = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: utamaHijau, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: isSubmitting ? null : () async {
                          if (emailCtrl.text.isEmpty || userCtrl.text.isEmpty || pwdCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Semua kolom (Email, Username, Password) wajib diisi!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setModalState(() { isSubmitting = true; });
                          try {
                            await _apiService.createUser(
                              username: userCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: pwdCtrl.text,
                              role: rolePilihan,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Akun '${userCtrl.text}' berhasil dibuat! User dapat merubah password setelah login."), backgroundColor: utamaHijau),
                              );
                            }
                          } catch (e) {
                            setModalState(() { isSubmitting = false; });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Buat Akun Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _tampilkanDialogGantiPassword(BuildContext context) {
    final lamaCtrl = TextEditingController();
    final baruCtrl = TextEditingController();
    final konfirmasiCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.vpn_key_rounded, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ganti Password Saya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("Privasi Keamanan: Admin/Superadmin tidak akan mengetahui password baru Anda.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: lamaCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password Lama / Sementara",
                        prefixIcon: const Icon(Icons.lock_open_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: baruCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password Baru (Rahasia)",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: konfirmasiCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Ulangi Password Baru",
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: isSubmitting ? null : () async {
                          if (lamaCtrl.text.isEmpty || baruCtrl.text.isEmpty || konfirmasiCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Semua kolom password wajib diisi!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (baruCtrl.text != konfirmasiCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Konfirmasi password baru tidak cocok!"), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          setModalState(() { isSubmitting = true; });
                          try {
                            await _apiService.changePassword(oldPassword: lamaCtrl.text, newPassword: baruCtrl.text);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Password berhasil diganti secara rahasia!"), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setModalState(() { isSubmitting = false; });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text("Gagal: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Password Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FITUR SARAN 2: PUSAT NOTIFIKASI & PERINGATAN DINI ---
  void _tampilkanPusatNotifikasi(BuildContext context, int zoneId, String namaZona) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _apiService.fetchZoneAlerts(zoneId),
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Peringatan Dini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(namaZona, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 30),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: utamaHijau)))
                  else if (snapshot.hasError)
                    Expanded(child: Center(child: Text("Gagal memuat peringatan: ${snapshot.error}")))
                  else if (!snapshot.hasData || (snapshot.data!['alerts'] as List).isEmpty)
                    const Expanded(child: Center(child: Text("Belum ada notifikasi atau peringatan aktif.")))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: (snapshot.data!['alerts'] as List).length,
                        itemBuilder: (context, idx) {
                          final alert = (snapshot.data!['alerts'] as List)[idx];
                          final severity = alert['severity'] ?? 'INFO';
                          Color cardColor = Colors.blue.shade50;
                          Color iconColor = Colors.blue;
                          IconData iconData = Icons.info_outline_rounded;
                          
                          if (severity == 'CRITICAL') {
                            cardColor = Colors.red.shade50;
                            iconColor = Colors.red;
                            iconData = Icons.warning_rounded;
                          } else if (severity == 'WARNING') {
                            cardColor = Colors.orange.shade50;
                            iconColor = Colors.orange;
                            iconData = Icons.thermostat_rounded;
                          } else if (severity == 'SAFE') {
                            cardColor = Colors.green.shade50;
                            iconColor = Colors.green;
                            iconData = Icons.check_circle_outline_rounded;
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: iconColor.withOpacity(0.3))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(iconData, color: iconColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(alert['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: iconColor)),
                                      const SizedBox(height: 4),
                                      Text(alert['message'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      const SizedBox(height: 6),
                                      Text(alert['timestamp'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.black45, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- FITUR SARAN 3: LAPORAN & EKSPOR DATA ANALISA ---
  void _tampilkanDialogLaporan(BuildContext context, int zoneId, String namaZona) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool isDownloading = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_rounded, color: Colors.blue, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Laporan & Analisa Panen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(namaZona, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("💡 Fitur Ekspor Data Skripsi:", style: TextStyle(fontWeight: FontWeight.bold, color: utamaHijau)),
                        SizedBox(height: 6),
                        Text("Semua catatan riwayat kelembapan tanah, suhu, pH, dan aktivitas pompa disajikan secara komplit dalam format tabel standar Excel (CSV).", style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: isDownloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.copy_rounded, color: Colors.white),
                      label: Text(isDownloading ? "Mengambil Data..." : "Salin Format Excel / CSV", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: isDownloading ? null : () async {
                        setModalState(() { isDownloading = true; });
                        try {
                          final csvData = await _apiService.fetchExportCsv(zoneId);
                          await Clipboard.setData(ClipboardData(text: csvData));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("📋 Berhasil disalin! Tinggal Paste di Excel, WhatsApp, atau Google Sheets Anda."),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() { isDownloading = false; });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text("Gagal mengunduh: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text("Atau unduh via browser: http://192.168.1.8:8000/api/zones/$zoneId/export/sensor", style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}