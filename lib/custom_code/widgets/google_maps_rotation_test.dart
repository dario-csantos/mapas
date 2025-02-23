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

class GoogleMapsRotationTest extends StatefulWidget {
  const GoogleMapsRotationTest({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<GoogleMapsRotationTest> createState() => _GoogleMapsRotationTestState();
}

class _GoogleMapsRotationTestState extends State<GoogleMapsRotationTest> {
  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng? _currentPosition;
  double _currentHeading = 0.0;
  double _currentSpeed = 0.0;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Inicia o rastreamento de localização e direção
  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });
  }

  /// Atualiza a posição e a rotação do mapa
  void _updateUserLocation(Position position) {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) {
      speedKmH = 0.0;
    }

    double heading = position.heading;
    if (heading.isNaN || heading < 0) {
      heading = _currentHeading;
    }

    setState(() {
      _currentPosition = newPosition;
      _currentHeading = heading;
      _currentSpeed = speedKmH;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: newPosition,
            zoom: 17,
            bearing: _currentHeading, // Faz o mapa girar
            tilt: 45,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          child: _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : gmaps.GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapController!.animateCamera(
                      gmaps.CameraUpdate.newCameraPosition(
                        gmaps.CameraPosition(
                          target: _currentPosition!,
                          zoom: 17,
                          bearing: _currentHeading,
                          tilt: 45,
                        ),
                      ),
                    );
                  },
                  initialCameraPosition: gmaps.CameraPosition(
                    target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
                    zoom: 17,
                  ),
                  markers: _currentPosition != null
                      ? {
                          gmaps.Marker(
                            markerId: const gmaps.MarkerId("user_position"),
                            position: _currentPosition!,
                            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                gmaps.BitmapDescriptor.hueBlue),
                          ),
                        }
                      : {},
                  myLocationEnabled: false,
                  compassEnabled: true,
                  trafficEnabled: false,
                ),
        ),

        // Exibição da velocidade
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
