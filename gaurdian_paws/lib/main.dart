import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/girl/simple_girl_home_screen.dart';
import 'screens/guardian/guardian_home_screen.dart';
import 'services/parse_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/background_alarm_service.dart';
import 'services/persistent_alarm_service.dart';
import 'services/simple_persistent_alarm_service.dart';
import 'services/ultra_simple_alarm_service.dart';
import 'services/minimal_alarm_service.dart';
import 'services/alarm_service.dart';
import 'services/emergency_service.dart';
import 'safety_engine/tap_pattern.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear all stored data to start fresh
  print('Clearing all previous data...');
  await SessionProvider.clearAllData();

  // Initialize Parse first since SessionProvider depends on it
  try {
    print('Initializing ParseService...');
    await ParseService.initialize();
    print('ParseService initialized successfully');
  } catch (e) {
    print('ParseService initialization failed: $e');
    return; // Exit if Parse fails to initialize
  }

  // Initialize NotificationService (Firebase will be skipped if not configured)
  try {
    print('Initializing NotificationService...');
    await NotificationService.initialize();
    print('NotificationService initialized successfully');
  } catch (e) {
    print('NotificationService initialization failed: $e');
  }

  // Initialize Minimal Alarm Service
  try {
    print('Initializing MinimalAlarmService...');
    await MinimalAlarmService.initialize();
    print('MinimalAlarmService initialized successfully');
  } catch (e) {
    print('MinimalAlarmService initialization failed: $e');
  }

  try {
    print('Starting app fresh...');
    runApp(
      ChangeNotifierProvider(
        create: (_) => SessionProvider()..loadFromStorage(),
        child: const GuardianPawsApp(),
      ),
    );
    print('App started successfully');
  } catch (e) {
    print('App startup failed: $e');
    rethrow;
  }
}

class GuardianPawsApp extends StatefulWidget {
  const GuardianPawsApp({super.key});

  @override
  State<GuardianPawsApp> createState() => _GuardianPawsAppState();
}

class _GuardianPawsAppState extends State<GuardianPawsApp> {
  static const platform = MethodChannel('guardian_paws/alarm');

  @override
  void initState() {
    super.initState();
    _setupPlatformChannel();
  }

  void _setupPlatformChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showAlarm') {
        // Show alarm overlay
        if (mounted) {
          // Get current context and show alarm
          final context = navigatorKey.currentContext;
          if (context != null) {
            // Load pattern from storage
            final prefs = await SharedPreferences.getInstance();
            final patternHash = prefs.getString('pattern_hash') ?? '';
            final patternLength = prefs.getInt('pattern_length') ?? 2;
            final patternAvgGap = prefs.getInt('pattern_avg_gap') ?? 500;
            
            // Show alarm with loaded pattern
            await AlarmService.showFullScreenAlarm(
              context,
              onSuccess: () {
                print('User confirmed safety via background alarm');
              },
              onEmergency: () async {
                print('Emergency triggered from background alarm');
                // Send emergency SMS
                final session = Provider.of<SessionProvider>(context, listen: false);
                if (session.currentUser?.id != null) {
                  List<String> guardianPhones = await EmergencyService.getGuardianPhoneNumbers(session.currentUser!.id);
                  await EmergencyService.sendEmergencySMS(guardianPhones);
                }
              },
              tapPattern: [TapZone.head, TapZone.tail], // Default pattern
              savedPatternHash: patternHash,
              savedPatternLength: patternLength,
              savedPatternAvgGap: patternAvgGap,
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Guardian-Paws',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xfff39c6b),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _buildHome(session),
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        SimpleGirlHomeScreen.routeName: (_) => const SimpleGirlHomeScreen(),
        GuardianHomeScreen.routeName: (_) => const GuardianHomeScreen(),
      },
    );
  }

  Widget _buildHome(SessionProvider session) {
    if (session.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!session.isLoggedIn) {
      return const LoginScreen();
    }

    if (session.isGirl) {
      return const SimpleGirlHomeScreen();
    }

    return const GuardianHomeScreen();
  }
}

// Global navigator key for accessing context from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

