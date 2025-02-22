// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:async';
import 'dart:math';

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
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
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  late gmaps.GoogleMapController _mapController;
  List<gmaps.LatLng> _routePoints = [];
  Timer? _updateTimer;
  double _currentSpeed = 0.0;
  gmaps.LatLng _currentPosition =
      gmaps.LatLng(-23.5505, -46.6333); // Início em São Paulo
  double _bearing = 0.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    _updateTimer = Timer.periodic(
        Duration(seconds: widget.updateIntervalSeconds), (timer) {
      _simulateMovement();
    });
  }

  void _simulateMovement() {
    // Simula um deslocamento de 0.0005 graus por iteração (~55 metros)
    final double delta = 0.0005;
    final double newLat = _currentPosition.latitude + delta * cos(_bearing);
    final double newLng = _currentPosition.longitude + delta * sin(_bearing);

    setState(() {
      _currentPosition = gmaps.LatLng(newLat, newLng);
      _routePoints.add(_currentPosition);
      _currentSpeed = 10.0; // Simula uma velocidade fixa de 10 km/h
      _bearing += 5; // Simula uma rotação ao longo do trajeto
    });

    _mapController.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: _currentPosition,
          zoom: widget.initialZoom,
          bearing: _bearing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          child: gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition,
              zoom: widget.initialZoom,
            ),
            polylines: {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId("simulated_route"),
                points: _routePoints,
                color: widget.routeColor,
                width: 5,
              ),
            },
            myLocationEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
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
                "${_currentSpeed.toStringAsFixed(1)} km/h",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
      ],
    );
  }
}
