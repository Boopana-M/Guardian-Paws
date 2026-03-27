import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../auth/login_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  static const routeName = '/guardian/home';

  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  Timer? _pollTimer;
  List<ParseObject> _linkedUsers = [];
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadLinkedUsers();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _loadLinkedUsers());
  }

  Future<void> _loadLinkedUsers() async {
    final current = await ParseUser.currentUser() as ParseUser?;
    if (current == null) return;
    final guardianQuery =
        QueryBuilder<ParseObject>(ParseObject('Guardian'))
          ..whereEqualTo('userId', current.objectId);
    final guardianRes = await guardianQuery.query();
    if (!guardianRes.success || guardianRes.results == null) return;
    final guardianObj = guardianRes.results!.first as ParseObject;
    final linkedUserIds =
        (guardianObj.get<List<dynamic>>('linkedUsers') ?? [])
            .cast<String>();
    if (linkedUserIds.isEmpty) return;
    final userQuery =
        QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereContainedIn('objectId', linkedUserIds);
    final usersRes = await userQuery.query();
    if (!usersRes.success || usersRes.results == null) return;
    final users = usersRes.results!.cast<ParseUser>();
    setState(() {
      _linkedUsers = users;
      _markers.clear();
      _polylines.clear();
    });
    for (final u in users) {
      final loc = u.get<ParseGeoPoint>('lastKnownLocation');
      if (loc != null) {
        final marker = Marker(
          markerId: MarkerId(u.objectId!),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: u.get<String>('name')),
        );
        setState(() {
          _markers.add(marker);
        });

        final trailQuery =
            QueryBuilder<ParseObject>(ParseObject('RiskLocationTrail'))
              ..whereEqualTo('userId', u.objectId)
              ..orderByAscending('createdAt');
        final trailRes = await trailQuery.query();
        if (trailRes.success && trailRes.results != null) {
          final points = <LatLng>[];
          for (final r in trailRes.results!.cast<ParseObject>()) {
            final p = r.get<ParseGeoPoint>('location');
            if (p != null) {
              points.add(LatLng(p.latitude, p.longitude));
            }
          }
          if (points.length > 1) {
            final polyline = Polyline(
              polylineId: PolylineId('trail_${u.objectId}'),
              points: points,
              color: Colors.redAccent,
              width: 4,
            );
            setState(() {
              _polylines.add(polyline);
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardian dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await session.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _linkedUsers.length,
              itemBuilder: (context, index) {
                final u = _linkedUsers[index] as ParseUser;
                final status = u.get<String>('status') ?? 'SAFE';
                final last =
                    u.get<DateTime>('lastCheckInTime');
                final battery =
                    u.get<num>('batteryLevel')?.toDouble();
                final deviceOnline =
                    u.get<bool>('deviceOnline') ?? true;
                return Container(
                  width: 260,
                  margin: const EdgeInsets.all(8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.get<String>('name') ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              color: status == 'SAFE'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last confirm: '
                            '${last != null ? last.toLocal().toString() : 'Never'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Battery: '
                            '${battery != null ? '${battery.toStringAsFixed(0)}%' : 'Unknown'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Device: ${deviceOnline ? 'Online' : 'Offline'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: deviceOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (c) => _mapController = c,
              markers: _markers,
              polylines: _polylines,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

