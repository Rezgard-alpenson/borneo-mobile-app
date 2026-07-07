import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../api_config.dart';
import '../widgets/top_snackbar.dart';

const Color utamaHijau = Color(0xFF1B5E20);
const Color latarAbu = Color(0xFFF4F7F4);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  bool _isLoading = false;
  // Fitur baru: State untuk kontrol visibility password
  bool _isPasswordVisible = false;
  
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _prosesLogin() async {
    if (_isLoading) return; 

    setState(() { _isLoading = true; }); 

    try {
      bool isSuccess = await _apiService.loginUser(
        _usernameCtrl.text, 
        _passwordCtrl.text
      );

      setState(() { _isLoading = false; }); 

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => DashboardScreen(isAdmin: SessionManager.isAdmin))
        );
      } else {
        if (mounted) {
          TopSnackBar.show(context, 'Login Gagal! Periksa kembali Username dan Password.', isError: true);
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        TopSnackBar.show(context, 'Error: ${e.toString().replaceAll("Exception: ", "")}', isError: true);
      }
    }
  }

  void _showIpSettingsDialog() {
    final TextEditingController ipCtrl = TextEditingController(text: ApiConfig.currentIpOnly);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet, color: utamaHijau),
            SizedBox(width: 10),
            Text('Atur IP Server Wi-Fi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat IP laptop/komputer server saat ini:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: latarAbu,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Contoh: 192.168.1.12',
                prefixIcon: const Icon(Icons.wifi, color: utamaHijau),
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: utamaHijau,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (ipCtrl.text.isNotEmpty) {
                await ApiConfig.setServerIp(ipCtrl.text);
                if (mounted) {
                  setState(() {}); // Memperbarui tampilan IP di layar login
                  Navigator.pop(ctx);
                  TopSnackBar.show(context, 'IP Server berhasil diubah ke: ${ApiConfig.baseUrl}');
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: utamaHijau,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24), 
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16), 
                    decoration: BoxDecoration(color: utamaHijau.withOpacity(0.1), shape: BoxShape.circle), 
                    child: const Icon(Icons.eco, size: 60, color: utamaHijau)
                  ),
                  const SizedBox(height: 16),
                  const Text('Borneo Agricola', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: utamaHijau)),
                  const Text('Sistem Monitoring Cerdas', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 40),
                  
                  TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      filled: true, fillColor: latarAbu, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                      labelText: 'Nama Pengguna', 
                      prefixIcon: const Icon(Icons.person_outline, color: utamaHijau)
                    )
                  ),
                  const SizedBox(height: 16),
                  
                  // TextField Password dengan fitur Icon Mata
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: !_isPasswordVisible, // Menggunakan state visibility
                    decoration: InputDecoration(
                      filled: true, fillColor: latarAbu, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                      labelText: 'Kata Sandi', 
                      prefixIcon: const Icon(Icons.lock_outline, color: utamaHijau),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: utamaHijau,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                          });
                        },
                      ),
                    )
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55), 
                      backgroundColor: utamaHijau, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: _prosesLogin, 
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24, width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                      : const Text('MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _showIpSettingsDialog,
                    icon: const Icon(Icons.settings_ethernet, size: 20, color: utamaHijau),
                    label: Text(
                      'Atur IP Server Wi-Fi (${ApiConfig.currentIpOnly})',
                      style: const TextStyle(color: utamaHijau, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}