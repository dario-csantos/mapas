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
  int _currentIndex = 0;
  double _currentSpeed = 10.0;
  bool _mapInitialized = false;
  Timer? _simulationTimer;

  // **📍 Lista de Coordenadas para Simular um Trajeto**
  final List<gmaps.LatLng> _routePoints = [
    gmaps.LatLng(-23.5505, -46.6333), // São Paulo (início)
    gmaps.LatLng(-23.5510, -46.6338),
    gmaps.LatLng(-23.5520, -46.6345),
    gmaps.LatLng(-23.5535, -46.6355),
    gmaps.LatLng(-23.5550, -46.6365), // Final do trajeto
  ];

  @override
  void initState() {
    super.initState();
    _startSimulatedMovement();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Simula o movimento seguindo os pontos da lista
  void _startSimulatedMovement() {
    _simulationTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_currentIndex < _routePoints.length - 1) {
        _currentIndex++;
        _updatePosition();
      } else {
        _simulationTimer
            ?.cancel(); // Para o movimento ao chegar ao destino final
      }
    });
  }

  /// Atualiza a posição do usuário no mapa
  void _updatePosition() {
    gmaps.LatLng newPosition = _routePoints[_currentIndex];

    setState(() {
      _currentSpeed = 10.0;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: newPosition,
            zoom: 17,
            bearing: _currentIndex * 45, // Simula rotação conforme avança
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
          child: gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_mapInitialized) {
                _mapInitialized = true;
                _updatePosition();
              }
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _routePoints.first,
              zoom: 17,
            ),
            markers: {
              gmaps.Marker(
                markerId: gmaps.MarkerId("user_position"),
                position: _routePoints[_currentIndex],
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueBlue),
              ),
            },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Velocidade: ${_currentSpeed.toStringAsFixed(1)} km/h",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "Posição: ${_routePoints[_currentIndex]}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
