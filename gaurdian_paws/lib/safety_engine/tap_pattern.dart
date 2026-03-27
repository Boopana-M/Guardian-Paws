import 'dart:math';

import 'package:bcrypt/bcrypt.dart';

enum TapZone { 
  head, 
  leftEar, 
  rightEar, 
  leftEye, 
  rightEye, 
  mouth, 
  bell, 
  body, 
  tail 
}

class TapEvent {
  final TapZone zone;
  final int millisSinceStart;

  TapEvent(this.zone, this.millisSinceStart);
}

class TapPattern {
  final String hash;
  final int expectedLength;
  final int avgGapMillis;

  TapPattern({
    required this.hash,
    required this.expectedLength,
    required this.avgGapMillis,
  });

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'expectedLength': expectedLength,
        'avgGapMillis': avgGapMillis,
      };

  static TapPattern fromJson(Map<String, dynamic> json) => TapPattern(
        hash: json['hash'] as String,
        expectedLength: json['expectedLength'] as int,
        avgGapMillis: json['avgGapMillis'] as int,
      );
}

class TapPatternEngine {
  static TapPattern createPattern(List<TapEvent> events) {
    final normalized = _normalize(events);
    final seq = normalized.join('-');
    final hash = BCrypt.hashpw(seq, BCrypt.gensalt());
    final gaps = <int>[];
    for (var i = 1; i < events.length; i++) {
      gaps.add(events[i].millisSinceStart - events[i - 1].millisSinceStart);
    }
    final avgGap = gaps.isEmpty
        ? 300
        : gaps.reduce((a, b) => a + b) ~/ max(1, gaps.length);
    return TapPattern(
      hash: hash,
      expectedLength: normalized.length,
      avgGapMillis: avgGap,
    );
  }

  static bool validate(
    TapPattern pattern,
    List<TapEvent> attempt,
  ) {
    if (attempt.isEmpty) return false;
    final normalized = _normalize(attempt);
    if ((normalized.length - pattern.expectedLength).abs() > 1) {
      return false;
    }
    final seq = normalized.join('-');
    final correct = BCrypt.checkpw(seq, pattern.hash);
    if (!correct) return false;

    final gaps = <int>[];
    for (var i = 1; i < attempt.length; i++) {
      gaps.add(attempt[i].millisSinceStart - attempt[i - 1].millisSinceStart);
    }
    if (gaps.isEmpty) return correct;
    final avgGap =
        gaps.reduce((a, b) => a + b) ~/ max<int>(1, gaps.length);
    final diffRatio =
        (avgGap - pattern.avgGapMillis).abs() / pattern.avgGapMillis;
    return diffRatio < 0.6;
  }

  static List<String> _normalize(List<TapEvent> events) {
    return events.map((e) => e.zone.name).toList(growable: false);
  }
}

