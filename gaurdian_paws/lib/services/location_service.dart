import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class LocationService {
  static final Battery _battery = Battery();
  static Timer? _riskTimer;

  static Future<void> updateDeviceStatus() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return;
    final hasPermission = await _ensurePermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final battery = await _battery.batteryLevel;

    user.set<ParseGeoPoint>(
      'lastKnownLocation',
      ParseGeoPoint(latitude: position.latitude, longitude: position.longitude),
    );
    user.set<num>('batteryLevel', battery);
    user.set<bool>('deviceOnline', true);
    await user.save();
  }

  static Future<void> startRiskTracking() async {
    _riskTimer?.cancel();
    _riskTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user == null) return;
      final hasPermission = await _ensurePermission();
      if (!hasPermission) return;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final battery = await _battery.batteryLevel;
      user.set<ParseGeoPoint>(
        'lastKnownLocation',
        ParseGeoPoint(
            latitude: position.latitude, longitude: position.longitude),
      );
      user.set<num>('batteryLevel', battery);
      await user.save();

      final trail = ParseObject('RiskLocationTrail')
        ..set<String>('userId', user.objectId!)
        ..set<ParseGeoPoint>(
          'location',
          ParseGeoPoint(
              latitude: position.latitude, longitude: position.longitude),
        )
        ..set<num>('batteryLevel', battery);
      await trail.save();
    });
  }

  static void stopRiskTracking() {
    _riskTimer?.cancel();
    _riskTimer = null;
  }

  static Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }
}

