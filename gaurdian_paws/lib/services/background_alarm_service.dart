import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_service.dart';
import '../safety_engine/tap_pattern.dart';

class BackgroundAlarmService {
  static const String channelId = 'guardian_paws_alarm';
  static const String channelName = 'Guardian Paws Safety Check';
  static const String channelDescription = 'Periodic safety check for protection mode';
  
  static bool _isInitialized = false;
  static Timer? _protectionTimer;
  static bool _isProtectionActive = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request necessary permissions
      await _requestPermissions();
      
      _isInitialized = true;
      print('BackgroundAlarmService initialized successfully');
    } catch (e) {
      print('Error initializing BackgroundAlarmService: $e');
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
  
  static Future<void> startProtectionMode({
    required int intervalMinutes,
    required TapPattern? pattern,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Stop any existing timer
      await stopProtectionMode();
      
      // Save protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('protection_active', true);
      await prefs.setInt('protection_interval', intervalMinutes);
      if (pattern != null) {
        await prefs.setString('pattern_hash', pattern.hash);
        await prefs.setInt('pattern_length', pattern.expectedLength);
        await prefs.setInt('pattern_avg_gap', pattern.avgGapMillis);
      }
      
      // Start simple timer for periodic alarms
      _startSimpleTimer(intervalMinutes);
      
      _isProtectionActive = true;
      print('Protection mode started with ${intervalMinutes} minute intervals');
    } catch (e) {
      print('Error starting protection mode: $e');
      throw Exception('Failed to start protection mode: $e');
    }
  }
  
  static void _startSimpleTimer(int intervalMinutes) {
    print('Starting simple timer for ${intervalMinutes} minutes');
    
    // Use a simple timer that works even when app is in background
    _protectionTimer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) async {
      try {
        if (_isProtectionActive) {
          print('Timer triggered - showing safety check');
          await _showAlarmOverlay();
        } else {
          print('Protection mode disabled, stopping timer');
          timer.cancel();
        }
      } catch (e) {
        print('Error in timer: $e');
      }
    });
  }
  
  static Future<void> stopProtectionMode() async {
    try {
      // Stop timer
      _protectionTimer?.cancel();
      _protectionTimer = null;
      
      // Clear protection state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('protection_active', false);
      
      _isProtectionActive = false;
      print('Protection mode stopped');
    } catch (e) {
      print('Error stopping protection mode: $e');
    }
  }
  
  static Future<bool> isProtectionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('protection_active') ?? false;
    } catch (e) {
      print('Error checking protection status: $e');
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
      print('Alarm triggered - showing safety check');
      
      // Wake up the screen
      await WakelockPlus.enable();
      
      // Show alarm overlay via platform channel
      const platform = MethodChannel('guardian_paws/alarm');
      await platform.invokeMethod('showAlarm');
    } catch (e) {
      print('Error showing alarm overlay: $e');
    }
  }
  
  static bool get isProtectionRunning => _isProtectionActive;
}
