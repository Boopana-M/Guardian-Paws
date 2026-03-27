import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionProvider extends ChangeNotifier {
  AppUser? currentUser;
  bool loading = true;

  bool get isLoggedIn => currentUser != null;
  bool get isGirl => currentUser?.role == 'girl';
  bool get isGuardian => currentUser?.role == 'guardian';

  // Function to clear all stored data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all SharedPreferences
      print('All local storage data cleared');
    } catch (e) {
      print('Error clearing local storage: $e');
    }
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('guardian_paws_user');
      if (userJson != null) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        currentUser = AppUser(
          id: data['id'] as String,
          name: data['name'] as String,
          email: data['email'] as String,
          phone: data['phone'] as String,
          role: data['role'] as String,
          imei: data['imei'] as String?,
          deviceModel: data['deviceModel'] as String?,
        );
      } else {
        // Add timeout to prevent hanging
        try {
          final user = await ParseUser.currentUser()
              .then((value) => value as ParseUser?)
              .timeout(const Duration(seconds: 5));
          if (user != null) {
            await refreshFromParse(user);
          }
        } catch (e) {
          print('Failed to load user from Parse: $e');
        }
      }
    } catch (e) {
      print('Error in loadFromStorage: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromParse(ParseUser user) async {
    try {
      await user.fetch().timeout(const Duration(seconds: 5));
      currentUser = AppUser(
        id: user.objectId!,
        name: user.get<String>('name') ?? '',
        email: user.emailAddress ?? '',
        phone: user.get<String>('phone') ?? '',
        role: user.get<String>('role') ?? 'girl',
        imei: user.get<String>('imei'),
        deviceModel: user.get<String>('deviceModel'),
        protectionModeActive: user.get<bool>('protectionModeActive') ?? false,
        checkIntervalMinutes: user.get<int>('checkInterval') ?? 15,
        lastCheckInTime: user.get<DateTime>('lastCheckInTime'),
        status: user.get<String>('status') ?? 'SAFE',
        deviceOnline: user.get<bool>('deviceOnline') ?? true,
        batteryLevel: (user.get<num>('batteryLevel')?.toDouble()),
      );
      await _persist();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh user from Parse: $e');
    }
  }

  Future<void> setUser(ParseUser user) async {
    await refreshFromParse(user);
  }

  Future<void> logout() async {
    await ParseUser.currentUser()?.then((value) {
      if (value != null) {
        (value as ParseUser).logout();
      }
    });
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guardian_paws_user');
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUser == null) return;
    final u = currentUser!;
    await prefs.setString(
      'guardian_paws_user',
      jsonEncode({
        'id': u.id,
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
        'role': u.role,
        'imei': u.imei,
        'deviceModel': u.deviceModel,
      }),
    );
  }
}

