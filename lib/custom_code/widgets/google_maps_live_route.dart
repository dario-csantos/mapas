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
    required this.userRouteColor, // 🔥 Nova cor para a polyline do usuário
    required this.showSpeed,
    required this.initialZoom,
    required this.showMarkers,
    required this.markerType,
    this.markerLocations = const [],
    this.polylineRota = const [], // 🔥 Rota salva do banco
  });

  final double? width;
  final double? height;
  final LatLng initialLocation;
  final int updateIntervalSeconds;
  final double minDistanceFilter;
  final Color routeColor; // 🔥 Cor da rota salva
  final Color userRouteColor; // 🔥 Cor do trajeto do usuário
  final bool showSpeed;
  final double initialZoom;
  final bool showMarkers;
  final String markerType;
  final List<LatLng> markerLocations;
  final List<LatLng> polylineRota; // 🔥 Rota salva do banco

  @override
  State<GoogleMapsLiveRoute> createState() => _GoogleMapsLiveRouteState();
}

class _GoogleMapsLiveRouteState extends State<GoogleMapsLiveRoute> {
  gmaps.GoogleMapController? _mapController;
  Set<gmaps.Polyline> _polylines = {};
  Set<gmaps.Marker> _markers = {};
  List<gmaps.LatLng> _routePoints =
      []; // 🔥 Armazena o trajeto atual do usuário
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
    _loadPolylineRota(); // 🔥 Carrega a polyline salva do banco
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
              tilt: 0.0,
            ),
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

  /// 🔥 Atualiza a posição do usuário e exibe a velocidade corretamente
  void _updateUserLocation(Position position) async {
    final gmaps.LatLng newPosition =
        gmaps.LatLng(position.latitude, position.longitude);

    // 🔥 Garante que a velocidade seja exibida corretamente
    double speedKmH = (position.speed * 3.6).clamp(0, 200);
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
      _routePoints.add(newPosition); // 🔥 Atualiza trajeto do usuário

      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId("user_position"),
          position: newPosition,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue),
        ),
      };

      _updatePolylines(); // 🔥 Atualiza as linhas no mapa
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

  /// 🔥 Carrega a rota salva do banco e define a linha do usuário
  void _loadPolylineRota() {
    setState(() {
      _updatePolylines();
    });
  }

  /// 🔥 Atualiza ambas as polylines no mapa
  void _updatePolylines() {
    List<gmaps.LatLng> rotaSalva = widget.polylineRota
        .map((latLng) => gmaps.LatLng(latLng.latitude, latLng.longitude))
        .toList();

    setState(() {
      _polylines = {
        // 🔥 Linha fixa da rota salva
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("polyline_rota"),
          points: rotaSalva,
          color: widget.routeColor,
          width: 5,
        ),
        // 🔥 Linha dinâmica do usuário
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("polyline_usuario"),
          points: _routePoints,
          color: widget.userRouteColor,
          width: 5,
        ),
      };
    });
  }

  Set<gmaps.Marker> _buildMarkers() {
    if (!widget.showMarkers) return {};

    return widget.markerLocations
        .map((location) => gmaps.Marker(
              markerId: gmaps.MarkerId(location.toString()),
              position: gmaps.LatLng(location.latitude, location.longitude),
            ))
        .toSet();
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
              _loadPolylineRota();
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentPosition ?? gmaps.LatLng(0.0, 0.0),
              zoom: widget.initialZoom,
            ),
            markers: _buildMarkers().union(_markers),
            polylines: _polylines,
            myLocationEnabled: false,
            compassEnabled: true,
            trafficEnabled: false,
          ),
        ),

        // 🔥 Mostra a velocidade atual no mapa
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
