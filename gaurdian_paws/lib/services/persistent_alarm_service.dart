import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_service.dart';
import '../safety_engine/tap_pattern.dart';

class PersistentAlarmService {
  static const String channelId = 'guardian_paws_persistent';
  static const String channelName = 'Guardian Paws Persistent Protection';
  static const String channelDescription = 'Persistent safety monitoring';
  
  static bool _isInitialized = false;
  static bool _isServiceRunning = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request all necessary permissions
      await _requestPermissions();
      
      // Initialize background service with foreground mode
      final service = FlutterBackgroundService();
      
      if (await service.isRunning()) {
        print('Persistent background service already running');
        _isInitialized = true;
        _isServiceRunning = true;
        return;
      }
      
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: channelId,
          initialNotificationTitle: 'Guardian Paws Protection',
          initialNotificationContent: 'Safety monitoring is active',
          foregroundServiceNotificationId: 999,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
        ),
      );
      
      _isInitialized = true;
      print('PersistentAlarmService initialized successfully');
    } catch (e) {
      print('Error initializing PersistentAlarmService: $e');
      _isInitialized = true;
    }
  }
  
  static Future<void> _requestPermissions() async {
    try {
      // Request all permissions needed for persistent background execution
      final permissions = [
        Permission.notification,
        Permission.systemAlertWindow,
        Permission.ignoreBatteryOptimizations,
      ];
      
      for (final permission in permissions) {
        if (!await permission.isGranted) {
          final result = await permission.request();
          print('${permission.toString()} permission: $result');
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }
  
  static Future<void> startPersistentProtection({
    required int intervalMinutes,
    required TapPattern? pattern,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Save protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('persistent_protection_active', true);
      await prefs.setInt('protection_interval', intervalMinutes);
      if (pattern != null) {
        await prefs.setString('pattern_hash', pattern.hash);
        await prefs.setInt('pattern_length', pattern.expectedLength);
        await prefs.setInt('pattern_avg_gap', pattern.avgGapMillis);
      }
      
      // Start persistent background service
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
        print('Persistent background service started');
      }
      
      _isServiceRunning = true;
      print('Persistent protection mode started with ${intervalMinutes} minute intervals');
    } catch (e) {
      print('Error starting persistent protection mode: $e');
      throw Exception('Failed to start persistent protection: $e');
    }
  }
  
  static Future<void> stopPersistentProtection() async {
    try {
      // Stop background service
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
        print('Stop service invoked');
      }
      
      // Clear protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('persistent_protection_active', false);
      
      _isServiceRunning = false;
      print('Persistent protection mode stopped');
    } catch (e) {
      print('Error stopping persistent protection mode: $e');
    }
  }
  
  static Future<bool> isPersistentProtectionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('persistent_protection_active') ?? false;
    } catch (e) {
      print('Error checking persistent protection status: $e');
      return false;
    }
  }
  
  static Future<int> getProtectionInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('protection_interval') ?? 15;
    } catch (e) {
      print('Error getting protection interval: $e');
      return 15;
    }
  }
  
  static Future<void> testPersistentAlarm() async {
    print('Testing persistent alarm - will trigger in 3 seconds');
    Timer(const Duration(seconds: 3), () {
      _showAlarmOverlay();
    });
  }
  
  static Future<void> _showAlarmOverlay() async {
    try {
      print('Persistent alarm triggered - showing safety check');
      
      // Wake up the screen
      await WakelockPlus.enable();
      
      // Show alarm overlay via platform channel
      const platform = MethodChannel('guardian_paws/alarm');
      await platform.invokeMethod('showAlarm');
    } catch (e) {
      print('Error showing persistent alarm overlay: $e');
    }
  }
  
  static bool get isServiceRunning => _isServiceRunning;
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    
    final prefs = await SharedPreferences.getInstance();
    final intervalMinutes = prefs.getInt('protection_interval') ?? 15;
    
    print('Persistent background service started with ${intervalMinutes} minute intervals');
    
    Timer? periodicTimer;
    
    // Set up persistent periodic alarm
    periodicTimer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      try {
        final isActive = await PersistentAlarmService.isPersistentProtectionActive();
        if (isActive) {
          print('Persistent timer triggered - showing safety check');
          await PersistentAlarmService._showAlarmOverlay();
        } else {
          print('Persistent protection mode disabled, stopping timer');
          timer.cancel();
        }
      } catch (e) {
        print('Error in persistent timer: $e');
      }
    });
    
    service.on('stopService').listen((event) {
      print('Stop persistent service event received');
      periodicTimer?.cancel();
    });
    
    // Keep service alive with periodic heartbeat
    Timer.periodic(const Duration(minutes: 1), (timer) {
      service.invoke('updateNotification', {
        'content': 'Guardian Paws Protection - Active',
        'title': 'Safety monitoring',
      });
    });
    
  } catch (e) {
    print('Error in persistent onStart: $e');
  }
}
