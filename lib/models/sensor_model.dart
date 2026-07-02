class SensorData {
  final double kelembapanTanah;
  final double suhuUdara;
  final double phTanah;
  final double debitAir;
  final bool statusHujan;

  SensorData({
    required this.kelembapanTanah,
    required this.suhuUdara,
    required this.phTanah,
    required this.debitAir,
    required this.statusHujan,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      kelembapanTanah: (json['kelembapan_tanah'] as num).toDouble(),
      suhuUdara: (json['suhu_udara'] as num).toDouble(),
      phTanah: (json['ph_tanah'] as num).toDouble(),
      debitAir: (json['debit_air'] as num).toDouble(),
      statusHujan: json['status_hujan'] as bool,
    );
  }
}