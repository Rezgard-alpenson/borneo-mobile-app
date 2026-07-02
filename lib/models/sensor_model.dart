class SensorData {
  final double kelembapanTanah;
  final double suhuUdara;
  final double phTanah;
  final double debitAir;
  final bool statusHujan;
  final String waktuRekam;

  SensorData({
    required this.kelembapanTanah,
    required this.suhuUdara,
    required this.phTanah,
    required this.debitAir,
    required this.statusHujan,
    required this.waktuRekam,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      kelembapanTanah: (json['kelembapan_tanah'] as num).toDouble(),
      suhuUdara: (json['suhu_udara'] as num).toDouble(),
      phTanah: (json['ph_tanah'] as num).toDouble(),
      debitAir: (json['debit_air'] as num).toDouble(),
      statusHujan: json['status_hujan'] as bool,
      waktuRekam: json['waktu_rekam'] != null ? strToTime(json['waktu_rekam'].toString()) : 'Baru saja',
    );
  }

  static String strToTime(String str) {
    try {
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.')[0];
        return "${parts[0]} $timePart";
      }
      return str;
    } catch (_) {
      return str;
    }
  }
}