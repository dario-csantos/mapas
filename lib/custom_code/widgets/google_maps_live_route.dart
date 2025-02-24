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
    required this.showSpeed,
    required this.initialZoom,
    required this.showMarkers,
    required this.showRecordedRoute, // 🔥 NOVO: Controla exibição da rota gravada
    required this.showUserRoute, // 🔥 NOVO: Controla exibição da rota do usuário
    required this.markerType,
    this.markerLocations = const [],
    this.polylineRota = const [],
  });

  final double? width;
  final double? height;
  final LatLng initialLocation;
  final int updateIntervalSeconds;
  final double minDistanceFilter;
  final Color routeColor;
  final bool showSpeed;
  final bool showMarkers;
  final bool showRecordedRoute; // 🔥 NOVO PARAMETRO
  final bool showUserRoute; // 🔥 NOVO PARAMETRO
  final double initialZoom;
  final String markerType;
  final List<LatLng> markerLocations;
  final List<LatLng> polylineRota;

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
    _loadPolylineRota();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    super.dispose();
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
              tilt: 0.0, // 🔥 Remove inclinação 3D
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

      _markers = {
        gmaps.Marker(
          markerId: const gmaps.MarkerId("user_position"),
          position: newPosition,
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
              gmaps.BitmapDescriptor.hueBlue),
        ),
      };

      _loadPolylineRota(); // 🔥 Atualiza a polyline quando o usuário se move
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

  /// 🔥 Carrega as polylines (rota gravada e do usuário) conforme os parâmetros de ativação
  void _loadPolylineRota() {
    Set<gmaps.Polyline> polylineSet = {};

    if (widget.showRecordedRoute && widget.polylineRota.isNotEmpty) {
      List<gmaps.LatLng> convertedPoints = widget.polylineRota
          .map((latLng) => gmaps.LatLng(latLng.latitude, latLng.longitude))
          .toList();

      polylineSet.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("polyline_rota"),
          points: convertedPoints,
          color: widget.routeColor,
          width: 5,
        ),
      );
    }

    if (widget.showUserRoute && _routePoints.isNotEmpty) {
      polylineSet.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("user_route"),
          points: _routePoints,
          color: Colors.blue, // 🔥 A rota do usuário será azul
          width: 4,
        ),
      );
    }

    setState(() {
      _polylines = polylineSet;
    });
  }

  /// 🔥 Adiciona os marcadores ao mapa
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
      ],
    );
  }
}
