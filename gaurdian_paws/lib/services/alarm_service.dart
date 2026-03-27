import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'emergency_service.dart';
import '../safety_engine/tap_pattern.dart';

class AlarmService {
  static AudioPlayer? _audioPlayer;
  static OverlayEntry? _overlayEntry;
  static Timer? _emergencyTimer;
  static bool _isShowing = false;

  static Future<void> showFullScreenAlarm(BuildContext context, {
    required Function onSuccess,
    required Function onEmergency,
    required List<TapZone> tapPattern,
    required String savedPatternHash,
    required int savedPatternLength,
    required int savedPatternAvgGap,
  }) async {
    if (_isShowing) return;

    _isShowing = true;
    
    // Keep screen awake
    await WakelockPlus.enable();
    
    // Play meow sound
    _playMeowSound();

    // Start 30-second emergency timer
    _startEmergencyTimer(onEmergency);

    // Show overlay
    _showAlarmOverlay(context, onSuccess, onEmergency, tapPattern, savedPatternHash, savedPatternLength, savedPatternAvgGap);
  }

  static void _playMeowSound() {
    _audioPlayer = AudioPlayer();
    _audioPlayer!.play(AssetSource('sounds/meow.mp3'));
  }

  static void _startEmergencyTimer(Function onEmergency) {
    _emergencyTimer = Timer(const Duration(seconds: 30), () {
      onEmergency();
      dismissAlarm();
    });
  }

  static void _showAlarmOverlay(BuildContext context, Function onSuccess, Function onEmergency, List<TapZone> tapPattern, String savedPatternHash, int savedPatternLength, int savedPatternAvgGap) {
    _overlayEntry = OverlayEntry(
      builder: (context) => _AlarmOverlay(
        onSuccess: onSuccess,
        onEmergency: onEmergency,
        tapPattern: tapPattern,
        savedPatternHash: savedPatternHash,
        savedPatternLength: savedPatternLength,
        savedPatternAvgGap: savedPatternAvgGap,
        onDismiss: dismissAlarm,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismissAlarm() {
    _emergencyTimer?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    WakelockPlus.disable();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  static bool get isShowing => _isShowing;
}

class _AlarmOverlay extends StatefulWidget {
  final Function onSuccess;
  final Function onEmergency;
  final List<TapZone> tapPattern;
  final String savedPatternHash;
  final int savedPatternLength;
  final int savedPatternAvgGap;
  final VoidCallback onDismiss;

  const _AlarmOverlay({
    required this.onSuccess,
    required this.onEmergency,
    required this.tapPattern,
    required this.savedPatternHash,
    required this.savedPatternLength,
    required this.savedPatternAvgGap,
    required this.onDismiss,
  });

  @override
  State<_AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<_AlarmOverlay> with TickerProviderStateMixin {
  List<TapEvent> currentTaps = [];
  DateTime? _start;
  bool showOkButton = false;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  void _onCatTap(TapZone zone) {
    if (_start == null) return;
    final now = DateTime.now();
    final millis = now.difference(_start!).inMilliseconds;
    setState(() {
      currentTaps.add(TapEvent(zone, millis));
      
      // Check if pattern matches using the pattern engine
      if (currentTaps.length >= widget.tapPattern.length) {
        // Try to validate with recent taps
        final recentTaps = currentTaps.length > widget.tapPattern.length * 2
            ? currentTaps.sublist(currentTaps.length - widget.tapPattern.length * 2)
            : currentTaps;
        
        // Create a test pattern from recent taps
        final testPattern = TapPatternEngine.createPattern(recentTaps);
        final savedPattern = TapPattern(
          hash: widget.savedPatternHash,
          expectedLength: widget.savedPatternLength,
          avgGapMillis: widget.savedPatternAvgGap,
        );
        
        if (TapPatternEngine.validate(savedPattern, recentTaps)) {
          showOkButton = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Full screen cat image
            Expanded(
              child: Stack(
                children: [
                  // Cat image fills entire screen
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/cat_working.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                  
                  // Detailed tap zones for alarm
                  Positioned.fill(
                    child: GestureDetector(
                      onTapUp: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final Offset localOffset = box.globalToLocal(details.globalPosition);
                        final Size size = box.size;
                        
                        // Determine tap zone based on position
                        TapZone zone;
                        if (localOffset.dx < size.width * 0.25) {
                          zone = TapZone.leftEar;
                        } else if (localOffset.dx < size.width * 0.35) {
                          zone = TapZone.leftEye;
                        } else if (localOffset.dx < size.width * 0.5) {
                          zone = TapZone.head;
                        } else if (localOffset.dx < size.width * 0.65) {
                          zone = TapZone.rightEye;
                        } else if (localOffset.dx < size.width * 0.75) {
                          zone = TapZone.rightEar;
                        } else {
                          zone = TapZone.tail;
                        }
                        
                        _onCatTap(zone);
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom section with proper padding
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions
                  const Text(
                    'Tap the pattern to confirm you\'re safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pattern: ${widget.tapPattern.map((zone) => _getZoneName(zone)).join(' → ')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Taps: ${currentTaps.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onEmergency();
                            widget.onDismiss();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Emergency'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: showOkButton ? () {
                            widget.onSuccess();
                            widget.onDismiss();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('I\'m Safe'),
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
}

enum AlarmTapZone { head, tail }
