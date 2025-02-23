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
import 'package:geolocator/geolocator.dart';
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
  Timer? _updateTimer;
  double _currentSpeed = 0.0;
  gmaps.LatLng? _currentPosition;
  double _currentBearing = 0.0;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão de localização negada.");
      return;
    }

    _updateTimer = Timer.periodic(
        Duration(seconds: widget.updateIntervalSeconds), (timer) async {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _updateUserLocation(newPosition);
    });
  }

  void _updateUserLocation(Position position) {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) {
      speedKmH = 0.0;
    }

    double heading = position.heading;
    if (heading.isNaN || heading < 0) {
      heading = _currentBearing;
    }

    setState(() {
      _currentSpeed = speedKmH;
      _currentBearing = heading;
      _currentPosition = newPosition;
      _drawnRoute.add(newPosition);
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
          polylineId: const gmaps.PolylineId("tracking_route"),
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
          bearing: heading,
        ),
      ),
    );
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
            target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
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
