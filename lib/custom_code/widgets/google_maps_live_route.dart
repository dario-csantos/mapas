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
    this.markerLocations = const [],
    this.polylineRota = const [], // 🔥 Novo parâmetro para a rota
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
  final List<LatLng> markerLocations; // 🔥 Lista de marcadores
  final List<LatLng> polylineRota; // 🔥 Lista de pontos para desenhar a rota

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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_mapController != null) {
        _mapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: _currentPosition!,
              zoom: widget.initialZoom,
              tilt: 60.0, // Inclinação da câmera
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
      locationSettings: const LocationSettings(
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
    });

    _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: newPosition,
          zoom: _currentZoom,
          bearing: _currentHeading,
          tilt: 60.0, // Inclinação da câmera
        ),
      ),
    );
  }

  /// 🔥 Carrega a rota (Polyline) no mapa
  void _loadPolylineRota() {
    setState(() {
      _polylines = {
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId("polyline_rota"),
          points: widget.polylineRota
              .map((p) => gmaps.LatLng(p.latitude, p.longitude))
              .toList(), // 🔥 Conversão necessária
          color: widget.routeColor,
          width: 5,
        ),
      };
    });
  }

  /// 🔥 Adiciona os marcadores ao mapa, convertendo LatLng do FlutterFlow para LatLng do Google Maps
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
              _loadPolylineRota(); // 🔥 Agora a Polyline será carregada corretamente
              if (_currentPosition != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
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
              target: _currentPosition ?? const gmaps.LatLng(0.0, 0.0),
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
