class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'girl' or 'guardian'
  final String? imei;
  final String? deviceModel;
  final bool protectionModeActive;
  final int checkIntervalMinutes;
  final DateTime? lastCheckInTime;
  final String status; // SAFE / RISK
  final bool deviceOnline;
  final double? batteryLevel;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.imei,
    this.deviceModel,
    this.protectionModeActive = false,
    this.checkIntervalMinutes = 15,
    this.lastCheckInTime,
    this.status = 'SAFE',
    this.deviceOnline = true,
    this.batteryLevel,
  });
}

