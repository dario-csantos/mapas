// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

class GoogleMapsLiveRoute extends StatefulWidget {
  const GoogleMapsLiveRoute({
    super.key,
    this.width,
    this.height,
    required this.initialLocation,
    required this.updateIntervalSeconds,
    required this.minDistanceFilter,
    required this.userRouteColor,
    required this.routeColor,
    required this.showSpeed,
    required this.showTraffic,
    required this.initialZoom,
    required this.mapTilt,
    required this.showMarkersLocations,
    required this.showUserRoute,
    required this.showPolylineSavedRoute,
    this.markerLocations = const [],
    this.polylineSavedRoute = const [],
  });

  final double? width;
  final double? height;
  final LatLng initialLocation;
  final int updateIntervalSeconds;
  final double minDistanceFilter;
  final Color userRouteColor;
  final Color routeColor;
  final bool showSpeed;
  final bool showTraffic;
  final double initialZoom;
  final double mapTilt;
  final bool showMarkersLocations;
  final bool showUserRoute;
  final bool showPolylineSavedRoute;
  final List<LatLng> markerLocations;
  final List<LatLng> polylineSavedRoute;

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  List<gmaps.LatLng> _userRoutePoints = [];
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  gmaps.LatLng? _currentPosition;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double _currentZoom = 16.0;

  bool _showTraffic = false;
  bool _showSavedRoute = false;
  bool _showMarkers = false;
  bool _showUserRoute = false;

  @override
  void initState() {
    super.initState();

// Ativa o wakelock para manter a tela ligada
    WakelockPlus.enable();

    _currentPosition = gmaps.LatLng(
        widget.initialLocation.latitude, widget.initialLocation.longitude);

    _getInitialPosition();
    _startTracking();
    _loadPolylineSavedRoute();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

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
              tilt: widget.mapTilt,
            ),
          ),
        );
      }
    });
  }

  void _loadPolylineSavedRoute() {
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "saved_route");

      if (_showSavedRoute) {
        List<gmaps.LatLng> convertedPoints = widget.polylineSavedRoute
            .map((latLng) => gmaps.LatLng(latLng.latitude, latLng.longitude))
            .toList();

        _polylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId("saved_route"),
            points: convertedPoints,
            color: widget.routeColor,
            width: 5,
          ),
        );
      }
    });
  }

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

  void _updateUserLocation(Position position) async {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    double speedKmH = position.speed * 3.6;
    if (speedKmH.isNaN || speedKmH < 0) {
      speedKmH = 0.0; // 🔥 Agora sempre exibe 0 se o usuário estiver parado
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
      _currentPosition = newPosition;
      _userRoutePoints.add(newPosition);

      _updateUserPolyline();
    });

    _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: newPosition,
          zoom: _currentZoom,
          bearing: _currentHeading,
          tilt: widget.mapTilt,
        ),
      ),
    );
  }

  void _updateUserPolyline() {
    setState(() {
      _polylines.removeWhere((poly) => poly.polylineId.value == "user_route");

      if (_showUserRoute) {
        _polylines.add(
          gmaps.Polyline(
            polylineId: const gmaps.PolylineId("user_route"),
            points: _userRoutePoints,
            color: widget.userRouteColor,
            width: 5,
          ),
        );
      }
    });
  }

  Set<gmaps.Marker> _buildMarkerUser() {
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId("user_position"),
        position: _currentPosition ??
            gmaps.LatLng(widget.initialLocation.latitude,
                widget.initialLocation.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue),
      ),
    };
  }

  Set<gmaps.Marker> _buildMarkers() {
    if (!_showMarkers) return {};
    //if (!widget.showMarkersLocations) return {};

    return widget.markerLocations.map((location) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(location.toString()),
        position: gmaps.LatLng(location.latitude, location.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        gmaps.GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _loadPolylineSavedRoute();
          },
          initialCameraPosition: gmaps.CameraPosition(
            target: _currentPosition ??
                gmaps.LatLng(widget.initialLocation.latitude,
                    widget.initialLocation.longitude),
            zoom: widget.initialZoom,
          ),
          markers: _buildMarkerUser().union(_buildMarkers()),
          polylines: _polylines,
          myLocationEnabled: false,
          compassEnabled: true,
          trafficEnabled: _showTraffic, // trafficEnabled: widget.showTraffic,
        ),

        /*Positioned(
          bottom: 140,
          right: 100,
          child:

          ElevatedButton(
            onPressed: () {
              print("Botão clicado!");
            },
            child: Text("Clique Aqui"),
          ),
        ),*/

        Positioned(
          bottom: 200,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showSavedRoute =
                    !_showSavedRoute; // 🔄 Alterna entre ativado e desativado
              });
              _loadPolylineSavedRoute(); // 🔥 Atualiza o mapa corretamente
            },
            child: Icon(_showSavedRoute ? Icons.route : Icons.route_outlined),
            backgroundColor: Colors.green,
          ),
        ),
        Positioned(
          bottom: 260, // 🔥 Ajuste a posição conforme necessário
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showMarkers =
                    !_showMarkers; // 🔄 Alterna entre ativado e desativado
              });
            },
            child: Icon(_showMarkers
                ? Icons.location_on
                : Icons.location_off), // 🔥 Ícone muda conforme o estado
            backgroundColor: Colors.red,
          ),
        ),
        Positioned(
          bottom: 320, // 🔥 Ajuste a posição conforme necessário
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showUserRoute =
                    !_showUserRoute; // 🔄 Alterna entre ativado e desativado
                _updateUserPolyline(); // 🔥 Atualiza a exibição da rota do usuário
              });
            },
            child: Icon(_showUserRoute
                ? Icons.timeline
                : Icons.timeline_outlined), // 🔥 Ícone muda conforme o estado
            backgroundColor: Colors.blue,
          ),
        ),
        Positioned(
          bottom: 140, // Ajuste a posição conforme necessário
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showTraffic =
                    !_showTraffic; // 🔄 Alterna entre ativado e desativado
              });
            },
            child: Icon(_showTraffic
                ? Icons.traffic
                : Icons.traffic_outlined), // 🔥 Ícone muda conforme estado
            backgroundColor: Colors.orange,
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
