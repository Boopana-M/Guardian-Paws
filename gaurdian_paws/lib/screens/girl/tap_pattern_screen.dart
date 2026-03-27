import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../../safety_engine/tap_pattern.dart';

class TapPatternScreen extends StatefulWidget {
  const TapPatternScreen({super.key});

  @override
  State<TapPatternScreen> createState() => _TapPatternScreenState();
}

class _TapPatternScreenState extends State<TapPatternScreen> {
  final List<TapEvent> _events = [];
  DateTime? _start;
  bool _recording = false;
  TapZone? _lastTappedZone;

  void _startRecording() {
    setState(() {
      _events.clear();
      _recording = true;
      _start = DateTime.now();
      _lastTappedZone = null;
    });
  }

  void _onTap(TapZone zone) {
    if (!_recording || _start == null) return;
    final now = DateTime.now();
    final millis = now.difference(_start!).inMilliseconds;
    setState(() {
      _events.add(TapEvent(zone, millis));
      _lastTappedZone = zone;
    });
    
    // Visual feedback
    _showTapFeedback(zone);
  }

  void _showTapFeedback(TapZone zone) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getZoneName(zone)} tapped!'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Color(0xfff39c6b),
      ),
    );
  }

  Future<void> _save() async {
    if (_events.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use at least 3 taps')),
      );
      return;
    }
    final pattern = TapPatternEngine.createPattern(_events);
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      user.set<String>('tapPatternHash', pattern.hash);
      user.set<Map<String, dynamic>>('tapPatternMeta', {
        'expectedLength': pattern.expectedLength,
        'avgGapMillis': pattern.avgGapMillis,
      });
      await user.save();
    }
    if (!mounted) return;
    Navigator.of(context).pop<TapPattern>(pattern);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff2e3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xfffff2e3), Color(0xfffef4ea)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Color(0xfff39c6b)),
                    ),
                    const Expanded(
                      child: Text(
                        'Secret kitty taps',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xfff39c6b),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cat image with visual tap zones
              Expanded(
                child: Stack(
                  children: [
                    // Cat image fills entire available space
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/cat_working.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                    
                    // Visual tap zone indicators
                    _buildVisualTapZones(),
                  ],
                ),
              ),
              
              // Pattern display section
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xfffff2e3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recording status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _recording ? Color(0xfff39c6b) : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _recording ? Icons.fiber_manual_record : Icons.stop,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _recording ? 'Recording...' : 'Stopped',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Pattern display
                    Text(
                      'Taps recorded: ${_events.length}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Pattern sequence display
                    if (_events.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xfff39c6b).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pattern Sequence:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: _events.asMap().entries.map((entry) {
                                final index = entry.key;
                                final event = entry.value;
                                final isLast = index == _events.length - 1;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLast ? Color(0xfff39c6b) : Color(0xfff39c6b).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${index + 1}. ${_getZoneName(event.zone)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLast ? Colors.white : Color(0xfff39c6b),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Control buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (_recording) {
                                _resetPattern();
                              } else {
                                _startRecording();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xfff39c6b),
                              side: const BorderSide(color: Color(0xfff39c6b)),
                            ),
                            child: Text(_recording ? 'Stop' : 'Start'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _events.length >= 3 ? _save : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfff39c6b),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Save pattern'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualTapZones() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          return Stack(
            children: [
              // Head zone - large central area
              _buildTapZone(
                left: screenWidth * 0.3,
                top: screenHeight * 0.15,
                width: screenWidth * 0.4,
                height: screenHeight * 0.25,
                zone: TapZone.head,
                label: 'Head',
              ),
              
              // Left ear zone
              _buildTapZone(
                left: screenWidth * 0.25,
                top: screenHeight * 0.08,
                width: screenWidth * 0.12,
                height: screenHeight * 0.12,
                zone: TapZone.leftEar,
                label: 'L-Ear',
              ),
              
              // Right ear zone
              _buildTapZone(
                left: screenWidth * 0.63,
                top: screenHeight * 0.08,
                width: screenWidth * 0.12,
                height: screenHeight * 0.12,
                zone: TapZone.rightEar,
                label: 'R-Ear',
              ),
              
              // Left eye zone
              _buildTapZone(
                left: screenWidth * 0.38,
                top: screenHeight * 0.22,
                width: screenWidth * 0.08,
                height: screenHeight * 0.06,
                zone: TapZone.leftEye,
                label: 'L-Eye',
              ),
              
              // Right eye zone
              _buildTapZone(
                left: screenWidth * 0.54,
                top: screenHeight * 0.22,
                width: screenWidth * 0.08,
                height: screenHeight * 0.06,
                zone: TapZone.rightEye,
                label: 'R-Eye',
              ),
              
              // Mouth zone
              _buildTapZone(
                left: screenWidth * 0.45,
                top: screenHeight * 0.32,
                width: screenWidth * 0.1,
                height: screenHeight * 0.08,
                zone: TapZone.mouth,
                label: 'Mouth',
              ),
              
              // Bell zone (if visible in image)
              _buildTapZone(
                left: screenWidth * 0.42,
                top: screenHeight * 0.38,
                width: screenWidth * 0.16,
                height: screenHeight * 0.08,
                zone: TapZone.bell,
                label: 'Bell',
              ),
              
              // Body zone - large central area
              _buildTapZone(
                left: screenWidth * 0.25,
                top: screenHeight * 0.45,
                width: screenWidth * 0.5,
                height: screenHeight * 0.35,
                zone: TapZone.body,
                label: 'Body',
              ),
              
              // Tail zone
              _buildTapZone(
                left: screenWidth * 0.7,
                top: screenHeight * 0.5,
                width: screenWidth * 0.25,
                height: screenHeight * 0.3,
                zone: TapZone.tail,
                label: 'Tail',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTapZone({
    required double left,
    required double top,
    required double width,
    required double height,
    required TapZone zone,
    required String label,
  }) {
    final isActive = _lastTappedZone == zone;
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onTap(zone),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.red : Color(0xfff39c6b),
              width: isActive ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isActive 
                ? Color(0xfff39c6b).withOpacity(0.3)
                : Color(0xfff39c6b).withOpacity(0.1),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xfff39c6b),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getZoneName(TapZone zone) {
    switch (zone) {
      case TapZone.head: return 'Head';
      case TapZone.leftEar: return 'L-Ear';
      case TapZone.rightEar: return 'R-Ear';
      case TapZone.leftEye: return 'L-Eye';
      case TapZone.rightEye: return 'R-Eye';
      case TapZone.mouth: return 'Mouth';
      case TapZone.bell: return 'Bell';
      case TapZone.body: return 'Body';
      case TapZone.tail: return 'Tail';
    }
  }

  void _resetPattern() {
    setState(() {
      _events.clear();
      _recording = false;
      _start = null;
      _lastTappedZone = null;
    });
  }

  void _savePattern() {
    _save();
  }
}

