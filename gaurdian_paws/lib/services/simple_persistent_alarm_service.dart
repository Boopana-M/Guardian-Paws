import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_service.dart';
import '../safety_engine/tap_pattern.dart';

class SimplePersistentAlarmService {
  static const String channelId = 'guardian_paws_simple';
  static const String channelName = 'Guardian Paws Simple Protection';
  
  static bool _isInitialized = false;
  static Timer? _protectionTimer;
  static bool _isProtectionActive = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request necessary permissions
      await _requestPermissions();
      
      _isInitialized = true;
      print('SimplePersistentAlarmService initialized successfully');
    } catch (e) {
      print('Error initializing SimplePersistentAlarmService: $e');
      _isInitialized = true;
    }
  }
  
  static Future<void> _requestPermissions() async {
    try {
      // Request overlay permission (for showing alarm over other apps)
      if (!await Permission.systemAlertWindow.isGranted) {
        final result = await Permission.systemAlertWindow.request();
        print('System alert window permission: $result');
      }
      
      // Request notification permission
      if (!await Permission.notification.isGranted) {
        final result = await Permission.notification.request();
        print('Notification permission: $result');
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
      
      // Stop any existing timer
      await stopPersistentProtection();
      
      // Save protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('simple_protection_active', true);
      await prefs.setInt('protection_interval', intervalMinutes);
      if (pattern != null) {
        await prefs.setString('pattern_hash', pattern.hash);
        await prefs.setInt('pattern_length', pattern.expectedLength);
        await prefs.setInt('pattern_avg_gap', pattern.avgGapMillis);
      }
      
      // Start simple timer for periodic alarms
      _startSimpleTimer(intervalMinutes);
      
      _isProtectionActive = true;
      print('Simple protection mode started with ${intervalMinutes} minute intervals');
    } catch (e) {
      print('Error starting simple protection mode: $e');
      throw Exception('Failed to start simple protection: $e');
    }
  }
  
  static void _startSimpleTimer(int intervalMinutes) {
    print('Starting simple timer for ${intervalMinutes} minutes');
    
    // Use a simple timer that works even when app is in background
    _protectionTimer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      try {
        if (_isProtectionActive) {
          print('Simple timer triggered - showing safety check');
          await _showAlarmOverlay();
        } else {
          print('Protection mode disabled, stopping timer');
          timer.cancel();
        }
      } catch (e) {
        print('Error in simple timer: $e');
      }
    });
  }
  
  static Future<void> stopPersistentProtection() async {
    try {
      // Stop timer
      _protectionTimer?.cancel();
      _protectionTimer = null;
      
      // Clear protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('simple_protection_active', false);
      
      _isProtectionActive = false;
      print('Simple protection mode stopped');
    } catch (e) {
      print('Error stopping simple protection mode: $e');
    }
  }
  
  static Future<bool> isPersistentProtectionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('simple_protection_active') ?? false;
    } catch (e) {
      print('Error checking simple protection status: $e');
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
  
  // For testing - triggers alarm immediately
  static Future<void> testAlarm() async {
    Timer(const Duration(seconds: 3), () {
      _showAlarmOverlay();
    });
  }
  
  static Future<void> _showAlarmOverlay() async {
    try {
      print('Simple alarm triggered - showing safety check');
      
      // Wake up the screen
      await WakelockPlus.enable();
      
      // Show alarm overlay via platform channel
      const platform = MethodChannel('guardian_paws/alarm');
      await platform.invokeMethod('showAlarm');
    } catch (e) {
      print('Error showing simple alarm overlay: $e');
    }
  }
  
  static bool get isProtectionRunning => _isProtectionActive;
}
