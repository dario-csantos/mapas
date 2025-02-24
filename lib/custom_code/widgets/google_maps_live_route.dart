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

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
    super.key,
    this.width,
    this.height,
    required this.initialLocation,
    required this.updateIntervalSeconds,
    required this.minDistanceFilter,
    required this.routeColor,
    required this.showSpeed,
    required this.initialZoom,
    required this.showMarkers,
    required this.markerType,
    required this.trajetoString, // 🔥 Recebe a lista de coordenadas em string
  });

  final double? width;
  final double? height;
  final LatLng initialLocation;
  final int updateIntervalSeconds;
  final double minDistanceFilter;
  final Color routeColor;
  final bool showSpeed;
  final double initialZoom;
  final bool showMarkers;
  final String markerType;
  final List<String> trajetoString; // 🔥 Lista de strings com coordenadas

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  Set<gmaps.Marker> _markers = {};
  List<gmaps.LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _currentPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _getInitialPosition();
    _startTracking();
    _loadRouteFromString(); // 🔥 Converte string em LatLng e desenha a linha
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  /// 🔥 Converte as strings de coordenadas para gmaps.LatLng
  void _loadRouteFromString() {
    _routePoints.clear();

    for (String coord in widget.trajetoString) {
      List<String> latLng = coord.split(",");
      if (latLng.length == 2) {
        double? lat = double.tryParse(latLng[0]);
        double? lng = double.tryParse(latLng[1]);

        if (lat != null && lng != null) {
          _routePoints.add(gmaps.LatLng(lat, lng));
        }
      }
    }

    setState(() {
      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("tracking_route"),
          points: _routePoints,
          color: widget.routeColor,
          width: 5,
        ),
      };
    });
  }

  /// Obtém a posição inicial com base no parâmetro initialLocation
  Future<void> _getInitialPosition() async {
    setState(() {
      _currentPosition = gmaps.LatLng(
          widget.initialLocation.latitude, widget.initialLocation.longitude);
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (_mapController != null) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _currentPosition!,
              zoom: widget.initialZoom,
              tilt: 60.0,
            ),
          ),
        );
      }
    });
  }

  /// Inicia o rastreamento da localização do usuário
  Future<void> _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("❌ Permissão negada.");
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position newPosition) {
      _updateUserLocation(newPosition);
    });

    _updateTimer = Timer.periodic(
        Duration(seconds: widget.updateIntervalSeconds), (timer) async {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _updateUserLocation(newPosition);
    });
  }

  /// Atualiza a posição do usuário, velocidade e mantém o zoom personalizado
  void _updateUserLocation(Position position) async {
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

    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }

    setState(() {
      _currentSpeed = speedKmH;
      _currentHeading = heading;
      _routePoints.add(newPosition);

      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("tracking_route"),
          points: _routePoints,
          color: widget.routeColor,
          width: 5,
        ),
      };
    });

    _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: newPosition,
          zoom: _currentZoom,
          bearing: _currentHeading,
          tilt: 60.0,
        ),
      ),
    );
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
              if (_currentPosition != null) {
                Future.delayed(Duration(milliseconds: 500), () {
                  _mapController!.animateCamera(
                    gmaps.CameraUpdate.newCameraPosition(
                      gmaps.CameraPosition(
                        target: _currentPosition!,
                        zoom: widget.initialZoom,
                        bearing: _currentHeading,
                      ),
                    ),
                  );
                });
              }
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
              zoom: widget.initialZoom,
            ),
            markers: _markers,
            polylines: _polylines, // 🔥 Agora desenha a Polyline
            myLocationEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
          ),
        ),

        // Exibição da velocidade
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
