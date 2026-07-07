import 'package:flutter/material.dart';

class TopSnackBar {
  static void show(BuildContext context, String message, {bool isError = false, Duration duration = const Duration(seconds: 4)}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    
    // Menghitung margin agar SnackBar floating di bagian atas layar
    final screenHeight = MediaQuery.of(context).size.height;
    final topMargin = screenHeight - 130 > 0 ? screenHeight - 130 : 400.0;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
          bottom: topMargin,
          left: 16,
          right: 16,
        ),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF1B5E20), // Merah untuk error, Hijau utama untuk sukses/info
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: duration,
      ),
    );
  }
}
