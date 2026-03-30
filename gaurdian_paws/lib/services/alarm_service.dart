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

  static AudioPlayer? get audioPlayer => _audioPlayer;

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
  bool isPatternCorrect = false;
  String patternStatus = 'Tap the pattern';
  int _correctTaps = 0;

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
      
      // Update pattern status
      patternStatus = 'Taps: ${currentTaps.length}';
      
      // Check if we have enough taps to validate
      if (currentTaps.length >= widget.savedPatternLength) {
        // Take the most recent taps for validation
        final recentTaps = currentTaps.length > widget.savedPatternLength + 2
            ? currentTaps.sublist(currentTaps.length - widget.savedPatternLength - 2)
            : currentTaps;
        
        // Create a test pattern from recent taps
        final testPattern = TapPatternEngine.createPattern(recentTaps);
        final savedPattern = TapPattern(
          hash: widget.savedPatternHash,
          expectedLength: widget.savedPatternLength,
          avgGapMillis: widget.savedPatternAvgGap,
        );
        
        // Validate the pattern
        isPatternCorrect = TapPatternEngine.validate(savedPattern, recentTaps);
        
        if (isPatternCorrect) {
          patternStatus = '✅ Pattern matched!';
          showOkButton = true;
        } else {
          patternStatus = 'Keep tapping...';
        }
      }
    });
  }

  void _resetPattern() {
    setState(() {
      currentTaps.clear();
      _start = DateTime.now();
      showOkButton = false;
      isPatternCorrect = false;
      patternStatus = 'Tap the pattern';
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
                    patternStatus,
                    style: TextStyle(
                      color: isPatternCorrect ? Colors.green : Colors.white70,
                      fontSize: 14,
                      fontWeight: isPatternCorrect ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      // Reset button
                      IconButton(
                        onPressed: _resetPattern,
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        tooltip: 'Reset Pattern',
                      ),
                      const SizedBox(width: 8),
                      
                      // Emergency button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            widget.onEmergency();
                            widget.onDismiss();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('🚨 Emergency'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Success button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: showOkButton ? () {
                            // Play success sound
                            AlarmService.audioPlayer?.stop();
                            widget.onSuccess();
                            widget.onDismiss();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: showOkButton ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            showOkButton ? '✅ I\'m Safe' : 'Keep tapping...',
                          ),
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
