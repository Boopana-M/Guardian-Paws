import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../providers/session_provider.dart';
import '../../services/minimal_alarm_service.dart';
import '../../services/alarm_service.dart';
import '../../services/emergency_service.dart';
import '../auth/login_screen.dart';
import 'protection_settings_screen.dart';
import 'guardian_management_screen.dart';
import 'tap_pattern_screen.dart';

class SimpleGirlHomeScreen extends StatefulWidget {
  static const routeName = '/girl/home';

  const SimpleGirlHomeScreen({super.key});

  @override
  State<SimpleGirlHomeScreen> createState() => _SimpleGirlHomeScreenState();
}

class _SimpleGirlHomeScreenState extends State<SimpleGirlHomeScreen> {
  bool _protectionActive = false;
  int _intervalMinutes = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserState();
    _checkMinimalProtectionStatus();
  }

  Future<void> _loadUserState() async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      await session.refreshFromParse(user);
      setState(() {
        _protectionActive = user.get<bool>('protectionModeActive') ?? false;
        _intervalMinutes = user.get<int>('checkInterval') ?? 15;
      });
      if (_protectionActive) {
        _startTimer();
      }
    }
  }

  Future<void> _checkMinimalProtectionStatus() async {
    final isPersistentActive = await MinimalAlarmService.isPersistentProtectionActive();
    if (isPersistentActive) {
      setState(() {
        _protectionActive = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (_) => _showSafetyCheck(),
    );
  }

  Future<void> _toggleProtection(bool value) async {
    if (value) {
      // When turning ON protection mode, open settings first
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ProtectionSettingsScreen(),
        ),
      );
      
      // Only proceed if user completed settings
      if (result != true) {
        return; // User cancelled, don't turn on protection mode
      }
    }

    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      user.set<bool>('protectionModeActive', value);
      user.set<int>('checkInterval', _intervalMinutes);
      await user.save();
      setState(() {
        _protectionActive = value;
      });
      
      if (value) {
        _startTimer();
      } else {
        _timer?.cancel();
        await MinimalAlarmService.stopPersistentProtection();
      }
    }
  }

  Future<void> _showSafetyCheck() async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SimpleSafetyCheckDialog(),
    );
    if (result == true) {
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user != null) {
        user.set<String>('status', 'SAFE');
        user.set<DateTime>('lastCheckInTime', DateTime.now().toUtc());
        await user.save();
        final func = ParseCloudFunction('onSafetyConfirmed');
        await func.execute();
      }
    } else {
      final func = ParseCloudFunction('onSafetyFailed');
      await func.execute();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff5f6),
      appBar: AppBar(
        title: const Text(
          'Guardian Paws',
          style: TextStyle(
            color: Color(0xfff39c6b),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xfff39c6b)),
            onPressed: () async {
              final session = Provider.of<SessionProvider>(context, listen: false);
              await session.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Protection Status',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _protectionActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _protectionActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _protectionActive,
                        onChanged: _toggleProtection,
                        activeColor: const Color(0xfff39c6b),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideY(),
              const SizedBox(height: 16),
              const Text(
                'Protection Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // When turning ON protection mode, open settings first
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => ProtectionSettingsScreen(),
                          ),
                        );
                        
                        // Only proceed if user completed settings
                        if (result != true) {
                          return; // User cancelled, don't turn on protection mode
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff39c6b),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Protection Settings'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_protectionActive) {
                          // Stop protection mode
                          await _toggleProtection(false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Stop Protection'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Guardian Management',
                    subtitle: 'Manage your guardians',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GuardianManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.fingerprint,
                    title: 'Tap Pattern',
                    subtitle: 'Set your safety pattern',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TapPatternScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: const Color(0xfff39c6b),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleSafetyCheckDialog extends StatelessWidget {
  const _SimpleSafetyCheckDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Safety Check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Are you safe?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, I\'m Safe'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Emergency'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
