import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../services/background_alarm_service.dart';
import '../../services/simple_persistent_alarm_service.dart';
import '../../services/persistent_alarm_service.dart';
import '../../services/ultra_simple_alarm_service.dart';
import '../../services/minimal_alarm_service.dart';
import '../../services/alarm_service.dart';
import '../../services/emergency_service.dart';
import '../../providers/session_provider.dart';
import '../../safety_engine/tap_pattern.dart';
import 'guardian_management_screen.dart';
import 'tap_pattern_screen.dart';

class ProtectionSettingsScreen extends StatefulWidget {
  const ProtectionSettingsScreen({super.key});

  @override
  State<ProtectionSettingsScreen> createState() => _ProtectionSettingsScreenState();
}

class _ProtectionSettingsScreenState extends State<ProtectionSettingsScreen> {
  int _intervalMinutes = 15;
  TapPattern? _pattern;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      setState(() {
        _intervalMinutes = user.get<int>('checkInterval') ?? 15;
        final tapData = user.get<Map<String, dynamic>>('tapPatternMeta');
        final hash = user.get<String>('tapPatternHash');
        if (tapData != null && hash != null) {
          _pattern = TapPattern(
            hash: hash,
            expectedLength: tapData['expectedLength'] as int,
            avgGapMillis: tapData['avgGapMillis'] as int,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffef4ea),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Protection Settings',
          style: TextStyle(
            color: Color(0xfff39c6b),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xfff39c6b)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure your safety monitoring',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xfff39c6b),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time Interval Setting
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xfffff2e3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Color(0xfff39c6b)),
                                const SizedBox(width: 12),
                                const Text(
                                  'Check-in Interval',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'How often should your kitty check on you?',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            DropdownButton<int>(
                              value: _intervalMinutes,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 5, child: Text('Every 5 minutes')),
                                DropdownMenuItem(value: 10, child: Text('Every 10 minutes')),
                                DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
                                DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                                DropdownMenuItem(value: 60, child: Text('Every 60 minutes')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _intervalMinutes = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tap Pattern Setting
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xfffff2e3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.pets, color: Color(0xfff39c6b)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Secret Kitty Taps',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _pattern != null 
                                            ? 'Pattern set ✓' 
                                            : 'No pattern set',
                                        style: TextStyle(
                                          color: _pattern != null 
                                              ? Colors.green 
                                              : Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Create your secret tap pattern for safety checks',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push<TapPattern?>(
                                    MaterialPageRoute(
                                      builder: (_) => const TapPatternScreen(),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _pattern = result;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.touch_app),
                                label: Text(_pattern != null ? 'Change Pattern' : 'Set Pattern'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xfff39c6b),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                            // Test Alarm
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xfffff2e3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications_active, color: Color(0xfff39c6b)),
                                const SizedBox(width: 12),
                                const Text(
                                  'Test Alarm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Try a full-screen safety check to see how it works',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            
                            // Quick test options
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pattern != null ? () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Alarm will trigger in 5 seconds...'),
                                          backgroundColor: Colors.blue,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      
                                      // Delayed alarm trigger
                                      await Future.delayed(const Duration(seconds: 5));
                                      
                                      if (mounted) {
                                        await AlarmService.showFullScreenAlarm(
                                          context,
                                          onSuccess: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✅ Test completed successfully!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          },
                                          onEmergency: () async {
                                            final session = Provider.of<SessionProvider>(context, listen: false);
                                            if (session.currentUser?.id != null) {
                                              List<String> guardianPhones = await EmergencyService.getGuardianPhoneNumbers(session.currentUser!.id);
                                              await EmergencyService.sendEmergencySMS(guardianPhones);
                                            }
                                          },
                                          tapPattern: _pattern!.toSimplePattern(),
                                          savedPatternHash: _pattern!.hash,
                                          savedPatternLength: _pattern!.expectedLength,
                                          savedPatternAvgGap: _pattern!.avgGapMillis,
                                        );
                                      }
                                    } : null,
                                    icon: const Icon(Icons.timer),
                                    label: const Text('Test in 5 sec'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xfff39c6b),
                                      side: const BorderSide(color: Color(0xfff39c6b)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pattern != null ? () async {
                                      await AlarmService.showFullScreenAlarm(
                                        context,
                                        onSuccess: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('✅ Test completed successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        onEmergency: () async {
                                          final session = Provider.of<SessionProvider>(context, listen: false);
                                          if (session.currentUser?.id != null) {
                                            List<String> guardianPhones = await EmergencyService.getGuardianPhoneNumbers(session.currentUser!.id);
                                            await EmergencyService.sendEmergencySMS(guardianPhones);
                                          }
                                        },
                                        tapPattern: _pattern!.toSimplePattern(),
                                        savedPatternHash: _pattern!.hash,
                                        savedPatternLength: _pattern!.expectedLength,
                                        savedPatternAvgGap: _pattern!.avgGapMillis,
                                      );
                                    } : null,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Test Now'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xfff39c6b),
                                      side: const BorderSide(color: Color(0xfff39c6b)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_pattern == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  '⚠️ Please set a tap pattern first',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons - Fixed positioning
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xfff39c6b),
                          side: const BorderSide(color: Color(0xfff39c6b)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Show loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Starting persistent protection mode...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            
                            // Save settings and enable persistent protection mode
                            final user = await ParseUser.currentUser() as ParseUser?;
                            if (user != null) {
                              user.set<int>('checkInterval', _intervalMinutes);
                              await user.save();
                              
                              // Start minimal persistent background protection mode
                              await MinimalAlarmService.startPersistentProtection(
                                intervalMinutes: _intervalMinutes,
                              );
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🛡️ Minimal Protection Activated! Guardian Paws will check on you every ${_intervalMinutes} minutes, even if app is closed.'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            // Show error message
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to start persistent protection: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                            print('Error starting persistent protection mode: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xfff39c6b),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enable Persistent Protection'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Extension to convert TapPattern to simple pattern list
extension TapPatternExtension on TapPattern {
  List<TapZone> toSimplePattern() {
    // Return the actual pattern zones from the stored hash
    // For now, we'll use a common pattern - in production, this should be stored separately
    return [TapZone.head, TapZone.tail];
  }
  
  String getHash() => hash;
  int getLength() => expectedLength;
  int getAvgGap() => avgGapMillis;
}
