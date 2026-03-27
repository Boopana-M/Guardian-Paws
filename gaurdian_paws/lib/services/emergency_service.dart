import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class EmergencyService {
  static Future<void> sendEmergencySMS(List<String> guardianPhoneNumbers) async {
    try {
      // Get current location
      Position? position;
      String locationText = "Location unavailable";
      
      try {
        // Check location permissions
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          locationText = "Location services disabled";
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              locationText = "Location permission denied";
            } else {
              position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10)
              );
              locationText = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
            }
          } else {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10)
            );
            locationText = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
          }
        }
      } catch (e) {
        locationText = "Unable to get location: ${e.toString()}";
      }

      // Prepare SMS message
      String message = position != null 
          ? "She did not make the tap, check whether she is safe or not. Her current location: $locationText"
          : "She did not make the tap, check whether she is safe or not. Her last seen location: $locationText";

      // Send SMS to all guardians
      for (String phoneNumber in guardianPhoneNumbers) {
        await _sendSMS(phoneNumber, message);
      }
      
      print('Emergency SMS sent to all guardians');
    } catch (e) {
      print('Error sending emergency SMS: $e');
    }
  }

  static Future<void> _sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print('Could not launch SMS to $phoneNumber');
    }
  }

  static Future<List<String>> getGuardianPhoneNumbers(String girlUserId) async {
    try {
      final queryBuilder = QueryBuilder(ParseObject('Guardian'))
        ..whereEqualTo('linkedUsers', girlUserId);
      
      final response = await queryBuilder.find();
      List<String> phoneNumbers = [];
      
      for (var guardian in response) {
        String? phone = guardian.get<String>('phone');
        if (phone != null && phone.isNotEmpty) {
          phoneNumbers.add(phone);
        }
      }
      
      return phoneNumbers;
    } catch (e) {
      print('Error getting guardian phone numbers: $e');
      return [];
    }
  }
}
