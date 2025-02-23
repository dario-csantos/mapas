// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:async';
import 'dart:math';

class GoogleMapsSimulation extends StatefulWidget {
  const GoogleMapsSimulation({
    super.key,
    this.width,
    this.height,
    required this.updateIntervalSeconds,
    required this.routeColor,
    required this.showSpeed,
    required this.initialZoom,
  });

  final double? width;
  final double? height;
  final int updateIntervalSeconds;
  final Color routeColor;
  final bool showSpeed;
  final double initialZoom;

  @override
  State<GoogleMapsSimulation> createState() => _GoogleMapsSimulationState();
}

class _GoogleMapsSimulationState extends State<GoogleMapsSimulation> {
  late gmaps.GoogleMapController _mapController;
  Set<gmaps.Polyline> _polylines = {};
  Set<gmaps.Marker> _markers = {};
  List<gmaps.LatLng> _drawnRoute = [];

  // Lista de coordenadas ajustadas para motocicleta (10-20m)
  final List<gmaps.LatLng> _routePoints = [
    gmaps.LatLng(37.135891, -8.543395),
    gmaps.LatLng(37.135858, -8.543616),
    gmaps.LatLng(37.135826, -8.543837),
    gmaps.LatLng(37.135794, -8.544058),
    gmaps.LatLng(37.135761, -8.544279),
    gmaps.LatLng(37.135729, -8.544351),
    gmaps.LatLng(37.135695, -8.544423),
    gmaps.LatLng(37.135548, -8.544541),
    gmaps.LatLng(37.135401, -8.544660),
    gmaps.LatLng(37.135289, -8.544875),
    gmaps.LatLng(37.135178, -8.545090),
    gmaps.LatLng(37.135190, -8.545262),
    gmaps.LatLng(37.135202, -8.545434),
    gmaps.LatLng(37.135232, -8.545476),
    gmaps.LatLng(37.135261, -8.545517),
    gmaps.LatLng(37.136798, -8.545834),
    gmaps.LatLng(37.138868, -8.546259),
    gmaps.LatLng(37.139153, -8.546215),
    gmaps.LatLng(37.139346, -8.546154),
    gmaps.LatLng(37.139541, -8.546450),
    gmaps.LatLng(37.140259, -8.546790),
    gmaps.LatLng(37.140444, -8.546837),
    gmaps.LatLng(37.140902, -8.546949),
    gmaps.LatLng(37.141399, -8.547124),
    gmaps.LatLng(37.141600, -8.547036),
    gmaps.LatLng(37.141729, -8.546886),
    gmaps.LatLng(37.142080, -8.545737),
    gmaps.LatLng(37.142159, -8.545396),
    gmaps.LatLng(37.143274, -8.544531),
    gmaps.LatLng(37.145841, -8.542498),
    gmaps.LatLng(37.146446, -8.541993),
    gmaps.LatLng(37.147157, -8.541235),
    gmaps.LatLng(37.147338, -8.540939),
    gmaps.LatLng(37.147504, -8.541018),
    gmaps.LatLng(37.147486, -8.541424),
    gmaps.LatLng(37.148097, -8.544504),
    gmaps.LatLng(37.148270, -8.544964),
    gmaps.LatLng(37.148486, -8.546200),
    gmaps.LatLng(37.148191, -8.546859),
    gmaps.LatLng(37.148514, -8.547589),
    gmaps.LatLng(37.149694, -8.549520),
    gmaps.LatLng(37.150866, -8.551821),
    gmaps.LatLng(37.151038, -8.552100),
    gmaps.LatLng(37.152088, -8.555709),
    gmaps.LatLng(37.152261, -8.557468),
  ];

  int _currentIndex = 0;
  Timer? _simulationTimer;
  double _currentSpeed = 30.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(
      Duration(seconds: widget.updateIntervalSeconds),
      (timer) {
        if (_currentIndex < _routePoints.length - 1) {
          _currentIndex++;
          _updatePosition();
        } else {
          _simulationTimer?.cancel();
        }
      },
    );
  }

  void _updatePosition() {
    gmaps.LatLng newPosition = _routePoints[_currentIndex];
    _drawnRoute.add(newPosition);
    double bearing =
        _calculateBearing(_routePoints[max(0, _currentIndex - 1)], newPosition);

    setState(() {
      _currentSpeed = Random().nextDouble() * 50 + 10;
      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId("user_position"),
          position: newPosition,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue),
        ),
      };
      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("simulation_route"),
          points: _drawnRoute,
          color: widget.routeColor,
          width: 5,
        ),
      };
    });

    _mapController.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: newPosition,
          zoom: widget.initialZoom,
          bearing: bearing,
        ),
      ),
    );
  }

  double _calculateBearing(gmaps.LatLng start, gmaps.LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double deltaLon = (end.longitude - start.longitude) * (pi / 180);
    double y = sin(deltaLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon);
    double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        gmaps.GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
          },
          initialCameraPosition: gmaps.CameraPosition(
            target: _routePoints.first,
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
        ),
        if (widget.showSpeed)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Velocidade: ${_currentSpeed.toStringAsFixed(1)} km/h",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
      ],
    );
  }
}
